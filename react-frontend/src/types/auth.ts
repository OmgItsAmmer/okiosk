// Auth states for the kiosk login flow
export const AuthState = {
  INITIAL: 'INITIAL',           // Shows login button only
  QR_GENERATED: 'QR_GENERATED', // QR code displayed, waiting for scan
  PENDING: 'PENDING',           // QR scanned, waiting for backend auth
  AUTHENTICATED: 'AUTHENTICATED', // Google login complete
  GUEST: 'GUEST',               // Guest session active
  UPGRADE_PENDING: 'UPGRADE_PENDING' // Guest upgrading to authenticated
} as const;

export type AuthState = typeof AuthState[keyof typeof AuthState];

export type UserType = 'guest' | 'authenticated';

export interface User {
  id: string;
  googleId?: string;
  email?: string;
  name: string;
  picture?: string;
  userType: UserType;
}

export interface AuthSession {
  sessionId: string;
  userId?: string;
  status: 'pending' | 'authenticated' | 'expired';
  createdAt: string;
  expiresAt: string;
}

export interface QRSession {
  sessionId: string;
  qrUrl: string;
  expiresAt: Date;
}

export interface AuthContextType {
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  authState: AuthState;
  sessionId: string | null;
  qrSession: QRSession | null;

  // Actions
  initiateLogin: () => Promise<void>;
  loginAsGuest: () => Promise<void>;
  upgradeToAuth: () => Promise<void>;
  cancelLogin: () => void;
  logout: () => void;

  // Legacy compatibility
  login: () => void;
  token: string | null;
  socket: any | null;
}
