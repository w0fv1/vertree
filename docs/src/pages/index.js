import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import HomepageFeatures from '@site/src/components/HomepageFeatures';

import Heading from '@theme/Heading';
import styles from './index.module.css';

function HomepageHeader() {
    const { siteConfig } = useDocusaurusContext();
    return (
        <header className={clsx('hero hero--primary', styles.heroBanner)}>
            <div className={styles.heroContainer}>
                {/* 左侧内容 */}
                <div className={styles.heroText}>
                    <Heading as="h1" className="hero__title">
                        {siteConfig.title}
                    </Heading>
                    <p className="hero__subtitle">{siteConfig.tagline}</p>
                    <div className={styles.buttons}>
                        <Link className="button button--secondary button--lg" to="/docs/intro">
                            快速开始 _>
                        </Link>
                        <Link className="button button--text button--lg" to="https://github.com/w0fv1/vertree/releases">
                            下载
                        </Link>
                    </div>
                </div>

                {/* 右侧图片 */}
                <img src="/vertree/img/vertree_brand.png" alt="Logo" className={styles.heroImage} />
            </div>
        </header>
    );
}


export default function Home() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout
      title={`Hello ${siteConfig.title}`}
      description="单文件版本管理工具 - 让每一次迭代都有备无患！">
      <HomepageHeader />
      <main>
        <HomepageFeatures />
      </main>
    </Layout>
  );
}
