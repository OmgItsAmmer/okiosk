import React from 'react';
import { motion } from 'framer-motion';
import './Loader.css';
import logo from '../assets/images/kks_new_logo_dark.png';

interface LoaderProps {
    fullScreen?: boolean;
    text?: string;
}

const Loader: React.FC<LoaderProps> = ({ fullScreen = true, text = "Loading moments..." }) => {
    return (
        <motion.div
            className={`loader-container ${fullScreen ? 'full-screen' : 'inline'}`}
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
        >
            <div className="loader-content">
                <div className="loader-visual">
                    {/* Rotating outer ring */}
                    <motion.div
                        className="outer-ring"
                        animate={{ rotate: 360 }}
                        transition={{ duration: 2, repeat: Infinity, ease: "linear" }}
                    />

                    {/* Inner glowing circle */}
                    <motion.div
                        className="inner-glow"
                        animate={{ scale: [1, 1.1, 1] }}
                        transition={{ duration: 1.5, repeat: Infinity, ease: "easeInOut" }}
                    />

                    {/* Logo/Icon */}
                    <div className="loader-logo-container">
                        <img src={logo} alt="Logo" className="loader-logo" />
                    </div>
                </div>

                {text && (
                    <motion.div
                        className="loader-text"
                        animate={{ opacity: [0.4, 1, 0.4] }}
                        transition={{ duration: 2, repeat: Infinity }}
                    >
                        {text}
                    </motion.div>
                )}
            </div>

            {/* Background elements for depth */}
            {fullScreen && (
                <div className="loader-background">
                    <div className="bg-blob blob-1"></div>
                    <div className="bg-blob blob-2"></div>
                </div>
            )}
        </motion.div>
    );
};

export default Loader;
