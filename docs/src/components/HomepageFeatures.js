import React from 'react';
import clsx from 'clsx';
import styles from './HomepageFeatures.module.css';

const FeatureList = [
  {
    title: 'Mosaicking',
    img: 'img/mosaicking.png',
    description: (
      <>
        Apply linear mosaicking to CASDA footprints to generate high quality WALLABY image cubes.
      </>
    ),
  },
  {
    title: 'Source finding',
    img: 'img/source-finding.jpg',
    description: (
      <>
        Execution of source finding algorithms (sofia) on WALLABY image cubes.
      </>
    ),
  },
  {
    title: 'ASKAP science',
    img: 'img/askap.jpg',
    description: (
      <>
        Assisting scientists with the computing for the full WALLABY survey - one of two projects currently running on the Australian SKA Pathfinder (ASKAP).
      </>
    ),
  },
];

function Feature({img, title, description}) {
  return (
    <div className={clsx('col col--4')}>
      <div className="text--center">
        <img className={styles.featureSvg} src={img} alt={title} />
      </div>
      <div className="text--center padding-horiz--md">
        <h3>{title}</h3>
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
