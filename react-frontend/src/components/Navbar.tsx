import React from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';
import './Navbar.css';

const Navbar: React.FC = () => {
    const { logout, user } = useAuth();
    const navigate = useNavigate();
    const location = useLocation();

    const handleLogout = () => {
        logout();
        navigate('/login');
    };

    // Don't show on login page
    if (location.pathname === '/login') return null;

    return (
        <nav className="global-navbar">
            <div className="navbar-logo" onClick={() => navigate('/order')}>
                <span className="logo-text">Cod's Kitchen</span>
            </div>

            <div className="navbar-actions">
                {user && (
                    <div className="user-info">
                        <span className="user-name">{user.name}</span>
                    </div>
                )}
                <button className="nav-logout-btn" onClick={handleLogout} title="Logout">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" className="nav-icon">
                        <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path>
                        <polyline points="16 17 21 12 16 7"></polyline>
                        <line x1="21" y1="12" x2="9" y2="12"></line>
                    </svg>
                    <span>Logout</span>
                </button>
            </div>
        </nav>
    );
};

export default Navbar;
