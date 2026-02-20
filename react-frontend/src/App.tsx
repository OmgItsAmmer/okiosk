import { useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import { CartProvider } from './context/CartContext';
import { SnackbarProvider } from './components/Snackbar';
import { useAuth } from './hooks/useAuth';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import OrderAssistant from './pages/OrderAssistant';
import MenuScreen from './pages/MenuScreen';
import CheckoutScreen from './pages/CheckoutScreen';
import { applyTheme } from './constants/colors';
import './App.css';

import Loader from './components/Loader';
import InactivityHandler from './components/InactivityHandler';
// ... rest of imports

// Protected Route Component
const ProtectedRoute = ({ children }: { children: React.ReactNode }) => {
  const { isAuthenticated, isLoading } = useAuth();

  if (isLoading) {
    return <Loader text="Verifying session..." />;
  }

  return isAuthenticated ? <>{children}</> : <Navigate to="/login" replace />;
};


function App() {
  useEffect(() => {
    // Initialize theme variables
    applyTheme('dark');
  }, []);

  return (
    <Router>
      <SnackbarProvider>
        <AuthProvider>
          <CartProvider>
            <InactivityHandler>
              <Routes>
            <Route path="/login" element={<Login />} />
            <Route
              path="/order"
              element={
                <ProtectedRoute>
                  <OrderAssistant />
                </ProtectedRoute>
              }
            />
            <Route
              path="/dashboard"
              element={
                <ProtectedRoute>
                  <Dashboard />
                </ProtectedRoute>
              }
            />
            <Route
              path="/menu"
              element={
                <ProtectedRoute>
                  <MenuScreen />
                </ProtectedRoute>
              }
            />
            <Route
              path="/checkout"
              element={
                <ProtectedRoute>
                  <CheckoutScreen />
                </ProtectedRoute>
              }
            />
            <Route path="/" element={<Navigate to="/login" replace />} />
              </Routes>
            </InactivityHandler>
          </CartProvider>
        </AuthProvider>
      </SnackbarProvider>
    </Router>
  );
}

export default App;
