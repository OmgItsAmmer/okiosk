import React, { useEffect, useRef, useCallback } from 'react';
import { useAuth } from '../hooks/useAuth';
import { useCart } from '../context/CartContext';

const INACTIVITY_TIMEOUT_MS = 2 * 60 * 1000; // 2 minutes

/** Listens for user activity and logs out after 2 minutes of inactivity. */
const InactivityHandler: React.FC<{ children: React.ReactNode }> = ({ children }) => {
    const { isAuthenticated, logout } = useAuth();
    const { onLogout } = useCart();
    const timeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);

    const handleLogout = useCallback(async () => {
        await onLogout();
        logout();
    }, [onLogout, logout]);

    const resetTimer = useCallback(() => {
        if (timeoutRef.current) {
            clearTimeout(timeoutRef.current);
        }
        if (!isAuthenticated) return;
        timeoutRef.current = setTimeout(handleLogout, INACTIVITY_TIMEOUT_MS);
    }, [isAuthenticated, handleLogout]);

    useEffect(() => {
        if (!isAuthenticated) {
            if (timeoutRef.current) {
                clearTimeout(timeoutRef.current);
                timeoutRef.current = null;
            }
            return;
        }

        resetTimer();

        const events = ['mousedown', 'mousemove', 'keydown', 'touchstart', 'scroll'];
        events.forEach((ev) => window.addEventListener(ev, resetTimer));

        return () => {
            events.forEach((ev) => window.removeEventListener(ev, resetTimer));
            if (timeoutRef.current) {
                clearTimeout(timeoutRef.current);
                timeoutRef.current = null;
            }
        };
    }, [isAuthenticated, resetTimer]);

    return <>{children}</>;
};

export default InactivityHandler;
