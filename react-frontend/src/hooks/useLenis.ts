import { useEffect } from 'react';
import Lenis from 'lenis';

export function useLenis(enabled = true) {
    useEffect(() => {
        if (!enabled) return;

        const lenis = new Lenis({
            duration: 1.2,
            easing: (t) => Math.min(1, 1.001 - Math.pow(2, -10 * t)),
            smoothWheel: true,
            anchors: true,
        });

        let frameId: number;

        const raf = (time: number) => {
            lenis.raf(time);
            frameId = requestAnimationFrame(raf);
        };

        frameId = requestAnimationFrame(raf);

        return () => {
            cancelAnimationFrame(frameId);
            lenis.destroy();
        };
    }, [enabled]);
}
