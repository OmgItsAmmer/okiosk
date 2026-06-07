import { useNavigate } from 'react-router-dom';
import { motion, useScroll, useTransform } from 'framer-motion';
import { useLenis } from '../hooks/useLenis';
import LandingReveal, { LandingRevealItem } from '../components/landing/LandingReveal';
import './LandingPage.css';

const CHECKLIST_ITEMS = [
    { label: 'urdu?', tag: 'YES', variant: 'default' as const },
    { label: 'english?', tag: 'YES', variant: 'default' as const },
    { label: 'roman urdu?', tag: 'YES', variant: 'default' as const },
    { label: '"bro you know what i mean"', tag: 'YES', variant: 'default' as const },
    { label: "grandpa's 4 min long voice note?", tag: 'Coming Soon', variant: 'orange' as const },
    { label: 'telepathy?', tag: '2027 UPDATE.', variant: 'orange' as const },
];

const CARDS = [
    {
        icon: 'friction',
        title: 'ZERO FRICTION',
        body: "Stop typing your password like it's 2005.",
    },
    {
        icon: 'choice',
        title: 'NO MORE "WHICH ONE?"',
        body: "Our bot handles the details so you don't have to.",
    },
    {
        icon: 'bolt',
        title: 'REAL-TIME EVERYTHING',
        body: 'If it is on the screen, it is in your hands. No cap.',
    },
];

const MARQUEE_ITEMS = [
    'AGENTIC ORDERING',
    'NO DROPDOWNS',
    'ROMAN URDU OK',
    '30 SECOND CHECKOUT',
    'TRADITIONAL E-COMMERCE IS COOKED',
];

function CardIcon({ type }: { type: string }) {
    if (type === 'friction') {
        return (
            <svg className="landing-card-svg landing-card-svg--accent" viewBox="0 0 32 32" aria-hidden="true">
                <path d="M4 8h6M4 16h10M4 24h8" stroke="currentColor" strokeWidth="2.5" />
                <path d="M18 8l10 8-10 8" fill="none" stroke="currentColor" strokeWidth="2.5" />
            </svg>
        );
    }
    if (type === 'choice') {
        return (
            <svg className="landing-card-svg" viewBox="0 0 32 32" aria-hidden="true">
                <circle cx="16" cy="16" r="11" fill="none" stroke="currentColor" strokeWidth="2" />
                <path d="M11 13h10M11 19h6" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
            </svg>
        );
    }
    return (
        <svg className="landing-card-svg" viewBox="0 0 32 32" aria-hidden="true">
            <path d="M18 3L8 18h8l-2 11 12-17h-8l2-9z" fill="none" stroke="currentColor" strokeWidth="2" strokeLinejoin="round" />
        </svg>
    );
}

export default function LandingPage() {
    const navigate = useNavigate();
    useLenis();

    const { scrollY } = useScroll();
    const navBorder = useTransform(scrollY, [0, 80], ['rgba(255,255,255,0)', 'rgba(255,255,255,0.08)']);
    const heroGlowY = useTransform(scrollY, [0, 600], [0, 120]);

    const goToLogin = () => navigate('/login');

    return (
        <div className="landing">
            <div className="landing-grain" aria-hidden="true" />
            <div className="landing-grid-bg" aria-hidden="true" />

            <motion.nav
                className="landing-nav"
                style={{ borderBottomColor: navBorder }}
                initial={{ y: -20, opacity: 0 }}
                animate={{ y: 0, opacity: 1 }}
                transition={{ duration: 0.6, ease: [0.22, 1, 0.36, 1] }}
            >
                <div className="landing-container landing-nav-inner">
                    <a href="#" className="landing-logo" onClick={(e) => e.preventDefault()}>
                        <span className="landing-logo-mark" />
                        OKIOSK
                    </a>
                    <ul className="landing-nav-links">
                        <li><a href="#story"><span>01</span> STORY</a></li>
                        <li><a href="#tech"><span>02</span> TECH</a></li>
                        <li><a href="#drops"><span>03</span> DROPS</a></li>
                    </ul>
                    <motion.button
                        type="button"
                        className="landing-btn landing-btn--primary landing-btn--nav"
                        onClick={goToLogin}
                        whileHover={{ scale: 1.03 }}
                        whileTap={{ scale: 0.98 }}
                    >
                        TEST THE APP
                    </motion.button>
                </div>
            </motion.nav>

            <section className="landing-hero" id="story">
                <motion.div className="landing-hero-glow" style={{ y: heroGlowY }} aria-hidden="true" />
                <div className="landing-container landing-hero-inner">
                    <motion.p
                        className="landing-hero-eyebrow"
                        initial={{ opacity: 0, x: -20 }}
                        animate={{ opacity: 1, x: 0 }}
                        transition={{ delay: 0.1, duration: 0.6 }}
                    >
                        Agentic commerce · Lahore → everywhere
                    </motion.p>

                    <div className="landing-hero-titles">
                        <motion.h1
                            className="landing-hero-title landing-hero-title--white"
                            initial={{ opacity: 0, y: 90, skewY: 3 }}
                            animate={{ opacity: 1, y: 0, skewY: 0 }}
                            transition={{ delay: 0.18, duration: 0.85, ease: [0.22, 1, 0.36, 1] }}
                        >
                            STOP CLICKING.
                        </motion.h1>
                        <motion.h1
                            className="landing-hero-title landing-hero-title--red"
                            initial={{ opacity: 0, y: 90, skewY: 3 }}
                            animate={{ opacity: 1, y: 0, skewY: 0 }}
                            transition={{ delay: 0.32, duration: 0.85, ease: [0.22, 1, 0.36, 1] }}
                        >
                            START BUYING.
                        </motion.h1>
                    </div>

                    <motion.p
                        className="landing-hero-sub"
                        initial={{ opacity: 0, y: 24 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ delay: 0.55, duration: 0.7 }}
                    >
                        Agentic Ordering is here. Traditional e-commerce is a fossil.
                        Roman Urdu, English, or Urdu — we speak your hunger.
                    </motion.p>

                    <motion.button
                        type="button"
                        className="landing-btn landing-btn--primary landing-btn--hero"
                        onClick={goToLogin}
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ delay: 0.72, duration: 0.6 }}
                        whileHover={{ scale: 1.02 }}
                        whileTap={{ scale: 0.98 }}
                    >
                        <span>TEST THE DEMO</span>
                        <svg viewBox="0 0 20 20" aria-hidden="true"><path d="M4 10h12M11 5l5 5-5 5" fill="none" stroke="currentColor" strokeWidth="1.8" /></svg>
                    </motion.button>
                </div>
            </section>

            <div className="landing-marquee" aria-hidden="true">
                <div className="landing-marquee-track">
                    {[...MARQUEE_ITEMS, ...MARQUEE_ITEMS].map((item, i) => (
                        <span key={`${item}-${i}`}>{item}<i>✦</i></span>
                    ))}
                </div>
            </div>

            <section className="landing-quote">
                <div className="landing-container">
                    <LandingReveal>
                        <div className="landing-quote-box">
                            <div className="landing-quote-accent" aria-hidden="true" />
                            <span className="landing-quote-mark">&ldquo;</span>
                            <p className="landing-quote-text">
                                &ldquo;your abba said &lsquo;yeh kya hai&rsquo; then ordered 5kg rice in 30 seconds&rdquo;
                            </p>
                            <p className="landing-quote-sub">NO TUTORIAL · NO ONBOARDING · NO PHD REQUIRED</p>
                        </div>
                    </LandingReveal>
                </div>
            </section>

            <section className="landing-features" id="tech">
                <div className="landing-container">
                    <div className="landing-features-grid">
                        <LandingReveal>
                            <p className="landing-section-index">02 — TECH</p>
                            <h2 className="landing-features-heading">WE UNDERSTAND YOU.</h2>
                            <p className="landing-features-desc">
                                The agent figures it out so you don&apos;t have to scroll through endless dropdowns.
                            </p>
                        </LandingReveal>

                        <ul className="landing-checklist">
                            {CHECKLIST_ITEMS.map((item, i) => (
                                <LandingRevealItem key={item.label} delay={i * 0.07} className="landing-checklist-item">
                                    <span className="landing-checklist-label">{item.label}</span>
                                    <span className={`landing-tag${item.variant === 'orange' ? ' landing-tag--orange' : ''}`}>
                                        [{item.tag}]
                                    </span>
                                </LandingRevealItem>
                            ))}
                        </ul>
                    </div>
                </div>
            </section>

            <section className="landing-cards" id="drops">
                <div className="landing-container">
                    <LandingReveal className="landing-cards-header">
                        <p className="landing-section-index">03 — DROPS</p>
                        <h2 className="landing-cards-heading">Built different. Literally.</h2>
                    </LandingReveal>
                    <div className="landing-cards-grid">
                        {CARDS.map((card, i) => (
                            <LandingReveal key={card.title} delay={i * 0.1} className="landing-card-wrap">
                                <motion.article
                                    className="landing-card"
                                    whileHover={{ y: -6 }}
                                    transition={{ type: 'spring', stiffness: 320, damping: 22 }}
                                >
                                    <CardIcon type={card.icon} />
                                    <h3 className="landing-card-title">{card.title}</h3>
                                    <p className="landing-card-body">{card.body}</p>
                                    <span className="landing-card-line" aria-hidden="true" />
                                </motion.article>
                            </LandingReveal>
                        ))}
                    </div>
                </div>
            </section>

            <footer className="landing-footer">
                <div className="landing-container landing-footer-inner">
                    <LandingReveal y={20}>
                        <span className="landing-logo">
                            <span className="landing-logo-mark" />
                            OKIOSK
                        </span>
                    </LandingReveal>
                    <LandingReveal y={20} delay={0.1}>
                        <div className="landing-footer-meta">
                            <p className="landing-footer-credit">BUILT BY AMMER SAEED</p>
                            <ul className="landing-footer-links">
                                <li><a href="#">TRADITIONAL E-COMMERCE IS COOKED</a></li>
                                <li><a href="#">PRIVACY</a></li>
                                <li><a href="#">TERMS</a></li>
                            </ul>
                        </div>
                    </LandingReveal>
                </div>
            </footer>
        </div>
    );
}
