import { useRef, type ReactNode } from 'react';
import { motion, useInView, type HTMLMotionProps } from 'framer-motion';

interface LandingRevealProps extends HTMLMotionProps<'div'> {
    children: ReactNode;
    delay?: number;
    y?: number;
}

export default function LandingReveal({
    children,
    delay = 0,
    y = 48,
    className,
    ...rest
}: LandingRevealProps) {
    const ref = useRef<HTMLDivElement>(null);
    const inView = useInView(ref, { once: true, margin: '-10% 0px' });

    return (
        <motion.div
            ref={ref}
            className={className}
            initial={{ opacity: 0, y }}
            animate={inView ? { opacity: 1, y: 0 } : { opacity: 0, y }}
            transition={{
                duration: 0.75,
                delay,
                ease: [0.22, 1, 0.36, 1],
            }}
            {...rest}
        >
            {children}
        </motion.div>
    );
}

export function LandingRevealItem({
    children,
    delay = 0,
    className,
}: {
    children: ReactNode;
    delay?: number;
    className?: string;
}) {
    const ref = useRef<HTMLLIElement>(null);
    const inView = useInView(ref, { once: true, margin: '-5% 0px' });

    return (
        <motion.li
            ref={ref}
            className={className}
            initial={{ opacity: 0, x: 24 }}
            animate={inView ? { opacity: 1, x: 0 } : { opacity: 0, x: 24 }}
            transition={{
                duration: 0.55,
                delay,
                ease: [0.22, 1, 0.36, 1],
            }}
        >
            {children}
        </motion.li>
    );
}
