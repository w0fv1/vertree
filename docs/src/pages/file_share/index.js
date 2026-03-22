import React, {useEffect, useMemo, useState} from 'react';
import Layout from '@theme/Layout';
import styles from './index.module.css';

function parseFragmentParams(hash) {
  const raw = hash.startsWith('#') ? hash.slice(1) : hash;
  return new URLSearchParams(raw);
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
  const token = params.get('t') || '';
  const port = params.get('p') || '';
  const ips = (params.get('ips') || '')
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);

  if (!token || !port || ips.length === 0) {
    return [];
  }

  return ips.map((ip) => ({
    id: `${ip}:${port}`,
    ip,
    downloadUrl: `http://${ip}:${port}/file-share/download/${token}`,
    probeUrl: `http://${ip}:${port}/file-share/probe/${token}`,
    pixelProbeUrl: `http://${ip}:${port}/file-share/pixel/${token}`,
  }));
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

  useEffect(() => {
    const onHashChange = () => setFragment(window.location.hash || '');
    window.addEventListener('hashchange', onHashChange);
    return () => window.removeEventListener('hashchange', onHashChange);
  }, []);

  const params = useMemo(() => parseFragmentParams(fragment), [fragment]);
  const fileName = useMemo(
    () => decodeBase64UrlUtf8(params.get('name')),
    [params],
  );
  const fileSize = useMemo(() => Number(params.get('size') || 0), [params]);
  const expiresAt = useMemo(() => params.get('exp'), [params]);
  const networkName = useMemo(
    () => decodeBase64UrlUtf8(params.get('net')),
    [params],
  );
  const candidates = useMemo(() => buildCandidates(params), [params]);

  useEffect(() => {
    if (candidates.length === 0) {
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
            window.location.replace(candidate.downloadUrl);
          }, 350);
        })
        .catch(() => {
          if (cancelled || resolved) {
            return;
          }
          pending -= 1;
          setCandidateStates((previous) => ({
            ...previous,
            [candidate.id]: 'failed',
          }));
          if (pending <= 0) {
            setStatus('failed');
          }
        });
    });

    return () => {
      cancelled = true;
    };
  }, [candidates]);

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
                <strong>{fileName || '未提供'}</strong>
              </div>
              <div>
                <span>文件大小</span>
                <strong>{formatBytes(fileSize)}</strong>
              </div>
              <div>
                <span>失效时间</span>
                <strong>{formatTime(expiresAt)}</strong>
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
                  <div className={styles.candidateUrl}>{candidate.downloadUrl}</div>
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
                    href={candidate.downloadUrl}
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
