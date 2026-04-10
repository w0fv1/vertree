import React, {useEffect, useMemo, useState} from 'react';
import Layout from '@theme/Layout';
import styles from './index.module.css';

const PAYLOAD_FRAGMENT_PREFIX = '#c1:';
const ROUTE_FRAGMENT_PREFIX = '#c2:';
const BASE85_ALPHABET =
  '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!$%&()*+-;<=>?@^_~[]:,.';
const BASE85_LOOKUP = Object.fromEntries(
  [...BASE85_ALPHABET].map((char, index) => [char, index]),
);

function logShareDebug(level, message, details = undefined) {
  const logger = console[level] || console.log;
  if (details === undefined) {
    logger(`[Vertree file_share] ${message}`);
    return;
  }
  logger(`[Vertree file_share] ${message}`, details);
}

function stripRetrySuffix(hash) {
  const retryIndex = hash.indexOf('&retry=');
  return retryIndex >= 0 ? hash.slice(0, retryIndex) : hash;
}

function parseFragmentParams(hash) {
  const normalizedHash = stripRetrySuffix(hash);
  const raw = normalizedHash.startsWith('#') ? normalizedHash.slice(1) : normalizedHash;
  return new URLSearchParams(raw);
}

function decodeBase85(value) {
  if (!value) {
    return new Uint8Array();
  }
  if (value.length % 5 === 1) {
    throw new Error('Invalid Base85 input length');
  }

  const output = [];
  for (let offset = 0; offset < value.length; ) {
    const chunkLength = Math.min(5, value.length - offset);
    let chunkValue = 0;
    for (let index = 0; index < 5; index += 1) {
      const digit =
        index < chunkLength ? BASE85_LOOKUP[value[offset + index]] : 84;
      if (digit === undefined) {
        throw new Error(`Invalid Base85 character: ${value[offset + index]}`);
      }
      chunkValue = chunkValue * 85 + digit;
    }

    const chunkBytes = [
      (chunkValue >>> 24) & 0xff,
      (chunkValue >>> 16) & 0xff,
      (chunkValue >>> 8) & 0xff,
      chunkValue & 0xff,
    ];
    const outputLength = chunkLength === 5 ? 4 : chunkLength - 1;
    output.push(...chunkBytes.slice(0, outputLength));
    offset += chunkLength;
  }

  return Uint8Array.from(output);
}

function readVarInt(bytes, offset) {
  let result = 0;
  let shift = 0;
  let cursor = offset;

  while (cursor < bytes.length) {
    const byte = bytes[cursor];
    cursor += 1;
    result |= (byte & 0x7f) << shift;
    if ((byte & 0x80) === 0) {
      return {value: result, offset: cursor};
    }
    shift += 7;
    if (shift > 63) {
      throw new Error('VarInt too large');
    }
  }

  throw new Error('Unexpected end of payload while reading VarInt');
}

function readUtf8(bytes, offset) {
  const {value: length, offset: start} = readVarInt(bytes, offset);
  const end = start + length;
  if (end > bytes.length) {
    throw new Error('UTF-8 field extends beyond payload size');
  }
  return {
    text: new TextDecoder().decode(bytes.slice(start, end)),
    offset: end,
  };
}

function readAscii(bytes, offset) {
  const {value: length, offset: start} = readVarInt(bytes, offset);
  const end = start + length;
  if (end > bytes.length) {
    throw new Error('ASCII field extends beyond payload size');
  }
  return {
    text: String.fromCharCode(...bytes.slice(start, end)),
    offset: end,
  };
}

function parseCompactShare(hash) {
  const normalizedHash = stripRetrySuffix(hash);
  if (!normalizedHash.startsWith(PAYLOAD_FRAGMENT_PREFIX)) {
    return null;
  }

  try {
    const payload = decodeURIComponent(
      normalizedHash.slice(PAYLOAD_FRAGMENT_PREFIX.length),
    );
    const bytes = decodeBase85(payload);
    if (bytes.length === 0) {
      logShareDebug('error', 'c1 payload is empty after decoding.', {
        hash: normalizedHash,
      });
      return null;
    }

    let offset = 0;
    const version = bytes[offset];
    offset += 1;
    if (version !== 1) {
      logShareDebug('error', 'Unsupported c1 payload version.', {
        hash: normalizedHash,
        version,
      });
      return null;
    }

    const tokenResult = readAscii(bytes, offset);
    const token = tokenResult.text;
    offset = tokenResult.offset;

    if (offset + 2 > bytes.length) {
      logShareDebug('error', 'c1 payload is truncated before port.', {
        hash: normalizedHash,
        offset,
        byteLength: bytes.length,
      });
      return null;
    }
    const port = (bytes[offset] << 8) | bytes[offset + 1];
    offset += 2;

    const ipCountResult = readVarInt(bytes, offset);
    const ipCount = ipCountResult.value;
    offset = ipCountResult.offset;

    const ips = [];
    for (let index = 0; index < ipCount; index += 1) {
      if (offset + 4 > bytes.length) {
        logShareDebug('error', 'c1 payload is truncated before LAN IP list ends.', {
          hash: normalizedHash,
          offset,
          index,
          ipCount,
          byteLength: bytes.length,
        });
        return null;
      }
      ips.push(
        `${bytes[offset]}.${bytes[offset + 1]}.${bytes[offset + 2]}.${bytes[offset + 3]}`,
      );
      offset += 4;
    }

    const fileSizeResult = readVarInt(bytes, offset);
    const fileSize = fileSizeResult.value;
    offset = fileSizeResult.offset;

    const expiresAtResult = readVarInt(bytes, offset);
    const expiresAt = String(expiresAtResult.value);
    offset = expiresAtResult.offset;

    const fileNameResult = readUtf8(bytes, offset);
    const fileName = fileNameResult.text;
    offset = fileNameResult.offset;

    const networkNameResult = readUtf8(bytes, offset);
    const networkName = networkNameResult.text;
    offset = networkNameResult.offset;

    if (offset !== bytes.length) {
      logShareDebug('error', 'c1 payload contains trailing bytes.', {
        hash: normalizedHash,
        offset,
        byteLength: bytes.length,
      });
      return null;
    }

    return {
      shareRef: token,
      port: String(port),
      ips,
      fileName,
      fileSize,
      expiresAt,
      networkName: networkName || '',
    };
  } catch (error) {
    logShareDebug('error', 'Failed to parse c1 payload.', {
      hash: normalizedHash,
      error,
    });
    return null;
  }
}

function parseCompactRoute(hash) {
  const normalizedHash = stripRetrySuffix(hash);
  if (!normalizedHash.startsWith(ROUTE_FRAGMENT_PREFIX)) {
    return null;
  }

  try {
    const payload = decodeURIComponent(
      normalizedHash.slice(ROUTE_FRAGMENT_PREFIX.length),
    );
    const [shareRef, portText, ipText] = payload.split('@');
    if (!shareRef || !portText || !ipText) {
      logShareDebug('error', 'c2 route payload is missing required parts.', {
        hash: normalizedHash,
        payload,
      });
      return null;
    }

    const port = parseInt(portText, 36);
    if (!Number.isFinite(port) || port <= 0 || port > 65535) {
      logShareDebug('error', 'c2 route port is invalid.', {
        hash: normalizedHash,
        portText,
      });
      return null;
    }

    const ips = ipText
      .split('.')
      .map((item) => item.trim().toLowerCase())
      .filter(Boolean)
      .map((item) => {
        if (!/^[0-9a-f]{8}$/.test(item)) {
          throw new Error(`Invalid compact IPv4 hex: ${item}`);
        }
        return [
          parseInt(item.slice(0, 2), 16),
          parseInt(item.slice(2, 4), 16),
          parseInt(item.slice(4, 6), 16),
          parseInt(item.slice(6, 8), 16),
        ].join('.');
      });

    if (ips.length === 0) {
      logShareDebug('error', 'c2 route did not produce any candidate LAN IP.', {
        hash: normalizedHash,
        payload,
      });
      return null;
    }

    return {
      shareRef,
      port: String(port),
      ips,
      fileName: '',
      fileSize: 0,
      expiresAt: '',
      networkName: '',
    };
  } catch (error) {
    logShareDebug('error', 'Failed to parse c2 route payload.', {
      hash: normalizedHash,
      error,
    });
    return null;
  }
}

function decodeBase64UrlUtf8(value) {
  if (!value) {
    return '';
  }
  try {
    const normalized = value.replace(/-/g, '+').replace(/_/g, '/');
    const padded = normalized.padEnd(Math.ceil(normalized.length / 4) * 4, '=');
    const binary = atob(padded);
    const bytes = Uint8Array.from(binary, (char) => char.charCodeAt(0));
    return new TextDecoder().decode(bytes);
  } catch (error) {
    return '';
  }
}

function formatBytes(bytes) {
  if (!Number.isFinite(bytes) || bytes <= 0) {
    return '-';
  }
  if (bytes < 1024) {
    return `${bytes} B`;
  }
  if (bytes < 1024 * 1024) {
    return `${(bytes / 1024).toFixed(1)} KB`;
  }
  if (bytes < 1024 * 1024 * 1024) {
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  }
  return `${(bytes / (1024 * 1024 * 1024)).toFixed(1)} GB`;
}

function formatTime(timestamp) {
  if (!timestamp) {
    return '-';
  }
  const date = new Date(Number(timestamp));
  if (Number.isNaN(date.getTime())) {
    return '-';
  }
  return new Intl.DateTimeFormat('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  }).format(date);
}

function buildCandidates(params) {
  const shareRef = params.shareRef || params.token || '';
  const port = params.port || '';
  const ips = (params.ips || []).filter(Boolean);

  if (!shareRef || !port || ips.length === 0) {
    return [];
  }

  return ips.map((ip) => ({
    id: `${ip}:${port}`,
    ip,
    pageUrl: `http://${ip}:${port}/file-share/page/${shareRef}`,
    infoUrl: `http://${ip}:${port}/file-share/info/${shareRef}`,
    downloadUrl: `http://${ip}:${port}/file-share/download/${shareRef}`,
    probeUrl: `http://${ip}:${port}/file-share/probe/${shareRef}`,
    pixelProbeUrl: `http://${ip}:${port}/file-share/pixel/${shareRef}`,
  }));
}

async function fetchShareInfo(candidate, timeoutMs = 2400) {
  const controller = new AbortController();
  const timeout = window.setTimeout(() => controller.abort(), timeoutMs);

  try {
    const response = await fetch(`${candidate.infoUrl}?ts=${Date.now()}`, {
      method: 'GET',
      mode: 'cors',
      cache: 'no-store',
      signal: controller.signal,
    });
    if (!response.ok) {
      throw new Error(`info failed: ${response.status}`);
    }
    const payload = await response.json();
    if (!payload?.success || !payload?.data) {
      throw new Error('info payload missing success/data');
    }
    return payload.data;
  } finally {
    window.clearTimeout(timeout);
  }
}

function probeWithFetch(candidate, timeoutMs = 2400) {
  const controller = new AbortController();
  const timeout = window.setTimeout(() => controller.abort(), timeoutMs);
  return fetch(`${candidate.probeUrl}?ts=${Date.now()}`, {
    method: 'GET',
    mode: 'cors',
    cache: 'no-store',
    signal: controller.signal,
  })
    .then((response) => {
      if (!response.ok) {
        throw new Error(`probe failed: ${response.status}`);
      }
      return response;
    })
    .finally(() => window.clearTimeout(timeout));
}

function probeWithImage(candidate, timeoutMs = 2400) {
  return new Promise((resolve, reject) => {
    const image = new Image();
    const timeout = window.setTimeout(() => {
      cleanup();
      reject(new Error('timeout'));
    }, timeoutMs);

    function cleanup() {
      window.clearTimeout(timeout);
      image.onload = null;
      image.onerror = null;
    }

    image.onload = () => {
      cleanup();
      resolve(candidate);
    };
    image.onerror = () => {
      cleanup();
      reject(new Error('image probe failed'));
    };
    image.src = `${candidate.pixelProbeUrl}?ts=${Date.now()}`;
  });
}

async function probeCandidate(candidate) {
  try {
    await probeWithFetch(candidate);
    return candidate;
  } catch (error) {
    await probeWithImage(candidate);
    return candidate;
  }
}

export default function FileSharePage() {
  const [fragment, setFragment] = useState(() =>
    typeof window === 'undefined' ? '' : window.location.hash || '',
  );
  const [status, setStatus] = useState('idle');
  const [selectedCandidate, setSelectedCandidate] = useState(null);
  const [candidateStates, setCandidateStates] = useState({});
  const [resolvedInfo, setResolvedInfo] = useState(null);

  useEffect(() => {
    const onHashChange = () => setFragment(window.location.hash || '');
    window.addEventListener('hashchange', onHashChange);
    return () => window.removeEventListener('hashchange', onHashChange);
  }, []);

  const shareParams = useMemo(() => {
    const normalizedFragment = stripRetrySuffix(fragment);
    const compactRoute = parseCompactRoute(fragment);
    if (compactRoute) {
      return compactRoute;
    }
    const compactShare = parseCompactShare(fragment);
    if (compactShare) {
      return compactShare;
    }
    const params = parseFragmentParams(fragment);
    const legacyParams = {
      shareRef: params.get('t') || '',
      port: params.get('p') || '',
      ips: (params.get('ips') || '')
        .split(',')
        .map((item) => item.trim())
        .filter(Boolean),
      fileName: decodeBase64UrlUtf8(params.get('name')),
      fileSize: Number(params.get('size') || 0),
      expiresAt: params.get('exp') || '',
      networkName: decodeBase64UrlUtf8(params.get('net')),
    };
    const hasLegacyRoute =
      legacyParams.shareRef && legacyParams.port && legacyParams.ips.length > 0;
    if (!hasLegacyRoute && normalizedFragment) {
      logShareDebug('error', 'Unable to resolve share params from fragment.', {
        fragment: normalizedFragment,
      });
    }
    return legacyParams;
  }, [fragment]);
  const fileName = useMemo(() => shareParams.fileName || '', [shareParams]);
  const fileSize = useMemo(() => Number(shareParams.fileSize || 0), [shareParams]);
  const expiresAt = useMemo(() => shareParams.expiresAt || '', [shareParams]);
  const networkName = useMemo(
    () => shareParams.networkName || '',
    [shareParams],
  );
  const candidates = useMemo(() => buildCandidates(shareParams), [shareParams]);
  const displayFileName = resolvedInfo?.fileName || fileName;
  const displayFileSize = resolvedInfo?.fileSize ?? fileSize;
  const displayExpiresAt = resolvedInfo?.expiresAt || expiresAt;

  useEffect(() => {
    setResolvedInfo(null);
  }, [fragment]);

  useEffect(() => {
    if (
      candidates.length === 0 ||
      (fileName && fileSize > 0 && expiresAt)
    ) {
      return undefined;
    }

    let cancelled = false;

    const hydrateInfo = async () => {
      for (const candidate of candidates) {
        try {
          const info = await fetchShareInfo(candidate, 1800);
          if (cancelled) {
            return;
          }
          setResolvedInfo(info);
          logShareDebug('log', 'Resolved share info from LAN endpoint.', {
            candidate,
            info,
          });
          return;
        } catch (error) {
          logShareDebug('warn', 'Failed to hydrate share info from candidate.', {
            candidate,
            error,
          });
        }
      }
    };

    hydrateInfo();

    return () => {
      cancelled = true;
    };
  }, [candidates, expiresAt, fileName, fileSize]);

  useEffect(() => {
    if (candidates.length === 0) {
      logShareDebug('error', 'No candidate routes resolved from current share params.', {
        fragment: stripRetrySuffix(fragment),
        shareParams,
      });
      setStatus('invalid');
      return undefined;
    }

    let cancelled = false;
    let resolved = false;
    let pending = candidates.length;

    setStatus('probing');
    setSelectedCandidate(null);
    setCandidateStates(
      Object.fromEntries(candidates.map((candidate) => [candidate.id, 'pending'])),
    );

    candidates.forEach((candidate) => {
      probeCandidate(candidate)
        .then(() => {
          if (cancelled || resolved) {
            return;
          }
          resolved = true;
          setSelectedCandidate(candidate);
          setCandidateStates(
            Object.fromEntries(
              candidates.map((item) => [
                item.id,
                item.id === candidate.id ? 'success' : 'stopped',
              ]),
            ),
          );
          setStatus('redirecting');
          window.setTimeout(() => {
            window.location.replace(candidate.pageUrl);
          }, 350);
        })
        .catch((error) => {
          if (cancelled || resolved) {
            return;
          }
          pending -= 1;
          logShareDebug('warn', 'Candidate probe failed.', {
            candidate,
            error,
          });
          setCandidateStates((previous) => ({
            ...previous,
            [candidate.id]: 'failed',
          }));
          if (pending <= 0) {
            logShareDebug('error', 'All candidate probes failed.', {
              fragment: stripRetrySuffix(fragment),
              candidates,
            });
            setStatus('failed');
          }
        });
    });

    return () => {
      cancelled = true;
    };
  }, [candidates, fragment, shareParams]);

  const headline = {
    idle: '准备开始局域网探测',
    probing: '正在自动探测可用下载地址',
    redirecting: '已选通，正在跳转下载',
    failed: '自动选路失败',
    invalid: '分享链接缺少必要参数',
  }[status];

  return (
    <Layout
      title="Vertree 文件分享"
      description="Vertree 局域网文件分享桥接页"
    >
      <main className={styles.page}>
        <section className={styles.hero}>
          <div className={styles.badge}>Vertree LAN Share</div>
          <h1>{headline}</h1>
          <p className={styles.description}>
            这个页面会优先尝试连通分享者电脑暴露出来的局域网地址。探测成功后会自动跳转到可下载的目标地址。
          </p>
        </section>

        <section className={styles.grid}>
          <article className={styles.card}>
            <h2>文件信息</h2>
            <div className={styles.metaList}>
              <div>
                <span>文件名</span>
                <strong>{displayFileName || '未提供'}</strong>
              </div>
              <div>
                <span>文件大小</span>
                <strong>{formatBytes(displayFileSize)}</strong>
              </div>
              <div>
                <span>失效时间</span>
                <strong>{formatTime(displayExpiresAt)}</strong>
              </div>
              {networkName ? (
                <div>
                  <span>分享网络</span>
                  <strong>{networkName}</strong>
                </div>
              ) : null}
            </div>
          </article>

          <article className={styles.card}>
            <h2>状态</h2>
            <p className={styles.statusText}>
              {status === 'redirecting' && selectedCandidate
                ? `已选中 ${selectedCandidate.ip}，即将开始下载。`
                : status === 'failed'
                  ? '浏览器没有自动探测到可用地址。你可以手动点击下面的候选下载链接，并先确认是否和分享者连接在同一网络。'
                  : status === 'invalid'
                    ? '当前链接参数不完整，请让分享者重新生成分享链接。'
                    : '正在后台并发测试多个候选地址，请稍候。'}
            </p>
            <p className={styles.note}>
              提示：某些浏览器或企业网络会限制从 HTTPS 页面直接探测 HTTP 局域网地址。如果自动跳转失败，手动点击下面的候选地址通常仍然可以下载。
            </p>
            {status === 'failed' ? (
              <div className={styles.failureHint}>
                没有探测到任何可用候选地址。请先确认接收方和分享方是否连接在同一个网络；
                {networkName ? `当前分享网络是“${networkName}”。` : '如果分享方使用的是 Wi‑Fi，也请确认两端连接的是同一个 Wi‑Fi。'}
              </div>
            ) : null}
          </article>
        </section>

        <section className={styles.card}>
          <div className={styles.sectionHeader}>
            <h2>候选地址</h2>
            <button
              className={styles.retryButton}
              type="button"
              onClick={() => setFragment(`${window.location.hash}&retry=${Date.now()}`)}
            >
              重新探测
            </button>
          </div>
          <div className={styles.candidateList}>
            {candidates.map((candidate) => (
              <div className={styles.candidateCard} key={candidate.id}>
                <div>
                  <div className={styles.candidateIp}>{candidate.ip}</div>
                  <div className={styles.candidateUrl}>{candidate.pageUrl}</div>
                </div>
                <div className={styles.candidateActions}>
                  <span
                    className={`${styles.candidateState} ${styles[candidateStates[candidate.id] || 'pending']}`}
                  >
                    {{
                      pending: '探测中',
                      success: '可用',
                      stopped: '已停止',
                      failed: '失败',
                    }[candidateStates[candidate.id] || 'pending']}
                  </span>
                  <a
                    className={styles.downloadButton}
                    href={candidate.pageUrl}
                  >
                    手动下载
                  </a>
                </div>
              </div>
            ))}
          </div>
        </section>
      </main>
    </Layout>
  );
}
