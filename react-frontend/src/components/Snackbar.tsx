import React, { createContext, useContext, useState, useCallback, useRef, useEffect } from 'react';
import './Snackbar.css';

type SnackbarType = 'success' | 'error' | 'warning';

interface SnackbarState {
    open: boolean;
    message: string;
    type: SnackbarType;
}

interface SnackbarContextType {
    showSnackbar: (message: string, type?: SnackbarType) => void;
    hideSnackbar: () => void;
}

const SnackbarContext = createContext<SnackbarContextType | undefined>(undefined);

interface SnackbarProviderProps {
    children: React.ReactNode;
}

export const SnackbarProvider: React.FC<SnackbarProviderProps> = ({ children }) => {
    const [snackbar, setSnackbar] = useState<SnackbarState>({
        open: false,
        message: '',
        type: 'success',
    });
    const timeoutRef = useRef<NodeJS.Timeout | null>(null);

    const hideSnackbar = useCallback(() => {
        setSnackbar(prev => ({ ...prev, open: false }));
    }, []);

    const showSnackbar = useCallback((message: string, type: SnackbarType = 'success') => {
        // Clear any existing timeout
        if (timeoutRef.current) {
            clearTimeout(timeoutRef.current);
        }

        setSnackbar({
            open: true,
            message,
            type,
        });

        // Auto-dismiss after 4 seconds
        timeoutRef.current = setTimeout(() => {
            hideSnackbar();
        }, 4000);
    }, [hideSnackbar]);

    // Cleanup on unmount
    useEffect(() => {
        return () => {
            if (timeoutRef.current) {
                clearTimeout(timeoutRef.current);
            }
        };
    }, []);

    const getIcon = () => {
        switch (snackbar.type) {
            case 'success':
                return '✓';
            case 'error':
                return '✕';
            case 'warning':
                return '⚠';
            default:
                return '✓';
        }
    };

    return (
        <SnackbarContext.Provider value={{ showSnackbar, hideSnackbar }}>
            {children}
            <div className={`snackbar-container ${snackbar.open ? 'visible' : ''}`}>
                <div className={`snackbar snackbar-${snackbar.type}`}>
                    <span className="snackbar-icon">{getIcon()}</span>
                    <span className="snackbar-message">{snackbar.message}</span>
                    <button className="snackbar-close" onClick={hideSnackbar}>
                        ✕
                    </button>
                </div>
            </div>
        </SnackbarContext.Provider>
    );
};

export const useSnackbar = (): SnackbarContextType => {
    const context = useContext(SnackbarContext);
    if (!context) {
        throw new Error('useSnackbar must be used within a SnackbarProvider');
    }
    return context;
};

export default SnackbarProvider;
