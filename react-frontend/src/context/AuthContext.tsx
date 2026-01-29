import React, { createContext, useState, useEffect, useCallback, useRef } from 'react';
import type { ReactNode } from 'react';
import { io, Socket } from 'socket.io-client';
import { AuthState } from '../types/auth';
import type { User, AuthContextType, QRSession } from '../types/auth';

const AuthContext = createContext<AuthContextType | undefined>(undefined);

const BACKEND_URL = import.meta.env.VITE_BACKEND_URL || 'http://localhost:3000';
const QR_SESSION_TIMEOUT_MS = 5 * 60 * 1000; // 5 minutes
const GUEST_SESSION_DURATION_MS = 24 * 60 * 60 * 1000; // 24 hours

interface AuthProviderProps {
    children: ReactNode;
}

interface AuthSuccessData {
    token: string;
    user: {
        id: string;
        googleId: string;
        email: string;
        name: string;
        picture?: string;
    };
}

export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
    const [user, setUser] = useState<User | null>(null);
    const [token, setToken] = useState<string | null>(null);
    const [isLoading, setIsLoading] = useState(true);
    const [authState, setAuthState] = useState<AuthState>(AuthState.INITIAL);
    const [sessionId, setSessionId] = useState<string | null>(null);
    const [qrSession, setQrSession] = useState<QRSession | null>(null);
    const [socket, setSocket] = useState<Socket | null>(null);

    const timeoutRef = useRef<NodeJS.Timeout | null>(null);
    const socketRef = useRef<Socket | null>(null);

    // Load stored session on mount
    useEffect(() => {
        const storedToken = localStorage.getItem('auth_token');
        const storedUser = localStorage.getItem('user');
        const storedExpiry = localStorage.getItem('session_expiry');

        if (storedToken && storedUser) {
            const userData = JSON.parse(storedUser) as User;

            // Check if guest session has expired
            if (userData.userType === 'guest' && storedExpiry) {
                const expiryTime = new Date(storedExpiry).getTime();
                if (Date.now() > expiryTime) {
                    // Guest session expired, clear storage
                    localStorage.removeItem('auth_token');
                    localStorage.removeItem('user');
                    localStorage.removeItem('session_expiry');
                    setIsLoading(false);
                    return;
                }
            }

            setToken(storedToken);
            setUser(userData);
            setAuthState(userData.userType === 'guest' ? AuthState.GUEST : AuthState.AUTHENTICATED);
        }
        setIsLoading(false);
    }, []);

    // Initialize WebSocket connection
    useEffect(() => {
        const newSocket = io(BACKEND_URL, {
            transports: ['websocket', 'polling'],
        });

        newSocket.on('connect', () => {
            console.log('WebSocket connected');
        });

        newSocket.on('disconnect', () => {
            console.log('WebSocket disconnected');
        });

        setSocket(newSocket);
        socketRef.current = newSocket;

        return () => {
            newSocket.close();
        };
    }, []);

    // Handle auth success from WebSocket
    const handleAuthSuccess = useCallback((data: AuthSuccessData) => {
        console.log('Authentication successful:', data);

        const authenticatedUser: User = {
            ...data.user,
            userType: 'authenticated'
        };

        // Store token and user
        localStorage.setItem('auth_token', data.token);
        localStorage.setItem('user', JSON.stringify(authenticatedUser));
        localStorage.removeItem('session_expiry'); // Authenticated users don't expire

        setToken(data.token);
        setUser(authenticatedUser);
        setAuthState(AuthState.AUTHENTICATED);
        setQrSession(null);
        setSessionId(null);

        // Clear timeout
        if (timeoutRef.current) {
            clearTimeout(timeoutRef.current);
            timeoutRef.current = null;
        }
    }, []);

    // Setup WebSocket listeners when session changes
    useEffect(() => {
        if (!sessionId || !socketRef.current) return;

        const socket = socketRef.current;

        socket.emit('join-session', sessionId);

        socket.on('joined', (joinedSessionId: string) => {
            console.log('Joined session:', joinedSessionId);
        });

        socket.on('auth-success', handleAuthSuccess);

        socket.on('auth-error', (data: { message: string }) => {
            console.error('Authentication error:', data);
            setAuthState(AuthState.INITIAL);
            setQrSession(null);
            setSessionId(null);
        });

        return () => {
            socket.off('joined');
            socket.off('auth-success');
            socket.off('auth-error');
        };
    }, [sessionId, handleAuthSuccess]);

    // Initiate QR login flow
    const initiateLogin = useCallback(async () => {
        const newSessionId = `session_${Date.now()}_${Math.random().toString(36).substring(7)}`;
        setSessionId(newSessionId);

        const qrUrl = `${BACKEND_URL}/api/auth/google?session_id=${newSessionId}`;
        const expiresAt = new Date(Date.now() + QR_SESSION_TIMEOUT_MS);

        setQrSession({
            sessionId: newSessionId,
            qrUrl,
            expiresAt
        });
        setAuthState(AuthState.QR_GENERATED);

        // Set timeout for QR expiration
        timeoutRef.current = setTimeout(() => {
            console.log('QR session expired');
            setAuthState(AuthState.INITIAL);
            setQrSession(null);
            setSessionId(null);
        }, QR_SESSION_TIMEOUT_MS);
    }, []);

    // Login as guest
    const loginAsGuest = useCallback(async () => {
        try {
            const response = await fetch(`${BACKEND_URL}/api/auth/guest-session`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                }
            });

            if (!response.ok) {
                throw new Error('Failed to create guest session');
            }

            const data = await response.json();

            const guestUser: User = {
                id: data.user_id,
                name: data.name || 'Guest',
                userType: 'guest'
            };

            const expiryTime = new Date(Date.now() + GUEST_SESSION_DURATION_MS);

            localStorage.setItem('auth_token', data.jwt);
            localStorage.setItem('user', JSON.stringify(guestUser));
            localStorage.setItem('session_expiry', expiryTime.toISOString());

            setToken(data.jwt);
            setUser(guestUser);
            setAuthState(AuthState.GUEST);
        } catch (error) {
            console.error('Failed to login as guest:', error);
            throw error;
        }
    }, []);

    // Upgrade guest to authenticated
    const upgradeToAuth = useCallback(async () => {
        if (authState !== AuthState.GUEST) return;

        setAuthState(AuthState.UPGRADE_PENDING);

        const newSessionId = `upgrade_${Date.now()}_${Math.random().toString(36).substring(7)}`;
        setSessionId(newSessionId);

        const qrUrl = `${BACKEND_URL}/api/auth/google?session_id=${newSessionId}&upgrade_from=${user?.id}`;
        const expiresAt = new Date(Date.now() + QR_SESSION_TIMEOUT_MS);

        setQrSession({
            sessionId: newSessionId,
            qrUrl,
            expiresAt
        });

        // Set timeout for QR expiration
        timeoutRef.current = setTimeout(() => {
            console.log('Upgrade session expired');
            setAuthState(AuthState.GUEST);
            setQrSession(null);
            setSessionId(null);
        }, QR_SESSION_TIMEOUT_MS);
    }, [authState, user]);

    // Cancel login flow
    const cancelLogin = useCallback(() => {
        if (timeoutRef.current) {
            clearTimeout(timeoutRef.current);
            timeoutRef.current = null;
        }

        // Return to appropriate state
        if (user?.userType === 'guest') {
            setAuthState(AuthState.GUEST);
        } else {
            setAuthState(AuthState.INITIAL);
        }

        setQrSession(null);
        setSessionId(null);
    }, [user]);

    // Logout
    const logout = useCallback(() => {
        localStorage.removeItem('auth_token');
        localStorage.removeItem('user');
        localStorage.removeItem('session_expiry');

        setToken(null);
        setUser(null);
        setAuthState(AuthState.INITIAL);
        setQrSession(null);
        setSessionId(null);

        if (timeoutRef.current) {
            clearTimeout(timeoutRef.current);
            timeoutRef.current = null;
        }
    }, []);

    // Legacy login function (just initiates QR login)
    const login = useCallback(() => {
        initiateLogin();
    }, [initiateLogin]);

    const value: AuthContextType = {
        user,
        isAuthenticated: authState === AuthState.AUTHENTICATED || authState === AuthState.GUEST,
        isLoading,
        authState,
        sessionId,
        qrSession,
        initiateLogin,
        loginAsGuest,
        upgradeToAuth,
        cancelLogin,
        logout,
        login,
        token,
        socket,
    };

    return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export { AuthContext };
