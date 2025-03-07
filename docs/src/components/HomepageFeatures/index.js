import clsx from 'clsx';
import Heading from '@theme/Heading';
import styles from './styles.module.css';

const FeatureList = [
  {
    title: '树状版本管理，清晰追溯文件脉络',
    description: (
      <>
          Vertree 采用树状结构管理文件版本，每一次修改都像树枝的生长，清晰记录文件的演化过程。您无需再面对杂乱无章的文件备份，通过直观的树状图，轻松追溯文件的任何历史版本，精准定位每一次修改的细节，让文件管理变得井然有序。
      </>
    ),
  },
  {
    title: '文件修改监控，实时守护文件安全',
    description: (
      <>
          Vertree 具备强大的文件修改监控功能，一旦文件发生变化，系统立即响应并自动备份。无论是意外修改还是有意调整，您都能实时收到通知，确保文件的每一次变动都在您的监督之下。这就像为您的文件配备了一位忠实的守卫，时刻守护着文件的安全与完整。
      </>
    ),
  },
  {
    title: '无感融入，专注工作不间断',
    description: (
      <>
          Vertree 设计简洁，操作便捷，不会对您的日常工作流程造成任何干扰。它安静地在后台运行，通过系统托盘和右键菜单即可完成大部分操作，无需繁琐的设置和复杂的操作界面。您无需频繁切换软件，即可轻松管理文件版本，让您可以全身心地投入到工作中，享受高效、顺畅的工作体验。
      </>
    ),
  },
];

function Feature({ title, description}) {
  return (
    <div className={clsx('col col--4')}>
      <br/>
      <br/>
      <br/>
      <div className="text--center padding-horiz--md">
        <Heading as="h3">{title}</Heading>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function HomepageFeatures() {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
