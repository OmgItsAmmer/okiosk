import React, { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import './OrderAssistant.css';
import ProductCard from '../components/ProductCard';
import { useAuth } from '../hooks/useAuth';
import { sendAiCommand } from '../services/aiService';
import type { Product } from '../types/menu';

import { useSnackbar } from '../components/Snackbar';
import { useCart } from '../context/CartContext';
import * as cartService from '../services/cartService';
import SuccessModal from '../components/SuccessModal';

// Avatar Images
import agentNormal from '../assets/images/AIAgent/agent_normal.png';
import agentProcessing from '../assets/images/AIAgent/agent_processing.png';
import agentSucceed from '../assets/images/AIAgent/agent_succed.png';
import agentFailed from '../assets/images/AIAgent/agent_failed.png';
import agentSmiling from '../assets/images/AIAgent/agent_smiling.png';

// Fallbacks/Mappings for requested states
const AVATAR_NORMAL = agentNormal;
const AVATAR_PROCESSING = agentProcessing;
const AVATAR_SUCCEED = agentSucceed;
const AVATAR_FAILED = agentFailed;
const AVATAR_SMILING = agentSmiling;

interface AiProductVariant {
    variant_id: number;
    variant_name: string;
    sell_price: number;
    stock: number;
    attributes?: any;
}

interface ChatMessage {
    type: 'text' | 'products' | 'variant' | 'cart_action' | 'bill' | 'cart_view' | 'checkout';
    text?: string;
    products?: Product[];
    variantProduct?: Product;
    variants?: AiProductVariant[];
    quantity?: number;
    sender: 'user' | 'assistant';
    actionData?: any;
}

// Guide Steps Data
const GUIDE_STEPS = [
    {
        avatar: AVATAR_SMILING,
        title: "Meet Your AI Cashier",
        description: "I'm your smart order assistant! No need to browse a huge menu , just talk to me naturally and I'll handle the rest.",
        tip: null,
        accent: '#E63946',
    },
    {
        avatar: AVATAR_SMILING,
        title: "Place an Order",
        description: "Tell me what you'd like in plain language. I understand natural conversation, so just say what you want!",
        tip: '"I want rice" or "Add a biscuit!"',
        accent: '#4CAF50',
    },
    {
        avatar: AVATAR_PROCESSING,
        title: "Check Your Cart",
        description: "Want to see what's in your order? Just ask me! I'll show you everything with prices and quantities.",
        tip: '"Show my cart" or "What have I ordered?"',
        accent: '#F77F00',
    },
    {   
        avatar: AVATAR_FAILED,
        title: "Update or Remove Items",
        description: "Changed your mind? No problem. Tell me to remove something or change the quantity — I'll update your cart instantly.",
        tip: '"Remove the biscuit" or "Change rice to 3"',
        accent: '#FFBE0B',
    },
    {
        avatar: AVATAR_SUCCEED,
        title: "Checkout & Pay",
        description: "When you're all set, just say the word! I'll summarize your order and take you through the checkout process.",
        tip: '"Checkout" or "I\'m done, place my order"',
        accent: '#4CAF50',
    },
    {
        avatar: AVATAR_SMILING,
        title: "Explore the Full Menu",
        description: "Prefer to browse visually? Tap 'Explore Menu' at the top to see all our items, then come back and tell me what you want!",
        tip: null,
        accent: '#E63946',
    },
];

// Intro Phases Data
const INTRO_PHASES = [
    {
        avatar: AVATAR_NORMAL,
        text: "Hey there, welcome to Cod's Kitchen. I’m your new cashier."
    },
    {
        avatar: AVATAR_SUCCEED,
        text: "You can tell me what you want, or say things like checkout or show cart. I’ll do it ,no messy menu exploration."
    },
    {
        avatar: AVATAR_FAILED,
        text: "I’m a small kid and I can make mistakes, so please don’t get angry at me."
    }
];

const OrderAssistant: React.FC = () => {
    const navigate = useNavigate();
    const { showSnackbar } = useSnackbar();
    const { user, sessionId, logout } = useAuth();

    // Success Modal State
    const [showSuccessModal, setShowSuccessModal] = useState(false);
    const [lastOrderId, setLastOrderId] = useState<string | number>('');

    // Help Guide State
    const [helpButtonShake, setHelpButtonShake] = useState(false);
    const [showGuide, setShowGuide] = useState(false);
    const [guideStep, setGuideStep] = useState(0);
    const [guideAnimating, setGuideAnimating] = useState(false);
    const [guideDirection, setGuideDirection] = useState<'next' | 'prev'>('next');

    // Layout & Intro State
    const [isPortrait, setIsPortrait] = useState(window.innerHeight > window.innerWidth);
    const [introStep, setIntroStep] = useState(() => {
        const seen = sessionStorage.getItem('asst_intro_seen');
        return seen ? 3 : 0;
    });
    const isIntro = introStep < 3;

    // Avatar State
    const [avatarState, setAvatarState] = useState<'normal' | 'processing' | 'success' | 'failed'>('normal');

    const [isProcessing, setIsProcessing] = useState(false);
    const [chatInput, setChatInput] = useState("");
    const [chatMessages, setChatMessages] = useState<ChatMessage[]>([
        { type: 'text', text: "Hello! How can I help you today?", sender: 'assistant' }
    ]);

    const { refreshCart, onLogout: clearCartOnLogout } = useCart();

    const inputRef = useRef<HTMLInputElement>(null);
    const chatEndRef = useRef<HTMLDivElement>(null);

    const scrollToBottom = () => {
        chatEndRef.current?.scrollIntoView({ behavior: "smooth" });
    };

    useEffect(() => {
        scrollToBottom();
    }, [chatMessages, introStep]);

    useEffect(() => {
        const handleResize = () => setIsPortrait(window.innerHeight > window.innerWidth);
        window.addEventListener('resize', handleResize);
        return () => window.removeEventListener('resize', handleResize);
    }, []);

    // Save intro state
    useEffect(() => {
        if (!isIntro) {
            sessionStorage.setItem('asst_intro_seen', 'true');
        }
    }, [isIntro]);

    // Help button shake on first visit (3 seconds), then save to cache
    useEffect(() => {
        if (isIntro) return;
        const seen = localStorage.getItem('asst_help_shake_seen');
        if (seen === 'true') return;
        setHelpButtonShake(true);
        const timer = setTimeout(() => {
            setHelpButtonShake(false);
            localStorage.setItem('asst_help_shake_seen', 'true');
        }, 3000);
        return () => clearTimeout(timer);
    }, [isIntro]);

    // Sync Avatar with Processing State & Auto-Reset Success/Fail
    useEffect(() => {
        if (isProcessing) {
            setAvatarState('processing');
        } else if (avatarState === 'processing') {
            setAvatarState('normal');
        }
    }, [isProcessing]);

    useEffect(() => {
        if (avatarState === 'success' || avatarState === 'failed') {
            const timer = setTimeout(() => setAvatarState('normal'), 3000);
            return () => clearTimeout(timer);
        }
    }, [avatarState]);

    const handleSendChat = async (overrideMsg?: string) => {
        const textToSend = overrideMsg || chatInput;
        if (!textToSend.trim()) return;

        if (!overrideMsg) {
            setChatMessages((prev: ChatMessage[]) => [...prev, { type: 'text', text: textToSend, sender: 'user' }]);
            setChatInput("");
        }

        setIsProcessing(true);

        try {
            const response = await sendAiCommand({
                prompt: textToSend,
                session_id: sessionId || undefined,
                customer_id: user?.id ? parseInt(user.id) : undefined
            });

            if (response.success) {
                const emotion = response.emotion ?? 'normal';
                if (emotion === 'happy') setAvatarState('success');
                else if (emotion === 'upset') setAvatarState('failed');
                else setAvatarState('normal');
                const newMessages: ChatMessage[] = [];

                if (response.actions_executed && response.actions_executed.length > 0) {
                    for (const actionStr of response.actions_executed) {
                        try {
                            const actionObj = JSON.parse(actionStr);
                            const actionType = actionObj.action_type;
                            const data = actionObj.data;

                            let msgType: ChatMessage['type'] = 'text';
                            let products: Product[] = [];
                            let variantProduct: Product | undefined;
                            let availableVariants: AiProductVariant[] = [];
                            let quantity: number = 1;
                            let actionData = data;

                            if (actionType === 'variant_selection') {
                                msgType = 'variant';
                                variantProduct = {
                                    product_id: data.product_id,
                                    name: data.product_name,
                                    description: '',
                                    base_price: '0',
                                    sale_price: '0',
                                    category_id: 0,
                                    ispopular: false,
                                    stock_quantity: 0,
                                    isVisible: true,
                                    image_url: null,
                                    created_at: null,
                                    brandID: 0,
                                    price_range: '',
                                    tag: '',
                                    alert_stock: 0
                                };
                                availableVariants = data.available_variants || [];
                                quantity = data.quantity || 1;
                            } else if (actionType === 'show_menu' || actionType === 'search_product' || actionType === 'search_results') {
                                msgType = 'products';
                                products = data.products || data.results || [];
                            } else if (['add_to_cart', 'remove_from_cart', 'update_quantity', 'clear_cart'].includes(actionType)) {
                                msgType = 'cart_action';
                            } else if (actionType === 'generate_bill') {
                                msgType = 'bill';
                                const cartData = await cartService.getCart(user?.id ? parseInt(user.id) : undefined, sessionId || undefined);
                                actionData = { ...data, cartItems: cartData.items, subtotal: cartData.subtotal, total_items: cartData.total_items };
                            } else if (actionType === 'view_cart') {
                                msgType = 'cart_view';
                                const cartData = await cartService.getCart(user?.id ? parseInt(user.id) : undefined, sessionId || undefined);
                                actionData = { ...data, cartItems: cartData.items, subtotal: cartData.subtotal, total_items: cartData.total_items };
                            } else if (actionType === 'checkout') {
                                msgType = 'checkout';

                                // Check for success and orderId in data
                                if (response.success && data && data.orderId) {
                                    setLastOrderId(data.orderId);
                                    setShowSuccessModal(true);
                                    setAvatarState('success');
                                }

                                // Still show bill/checkout summary if needed, or just a success message
                                const cartData = await cartService.getCart(user?.id ? parseInt(user.id) : undefined, sessionId || undefined);
                                actionData = { ...data, cartItems: cartData.items, subtotal: cartData.subtotal };
                            }

                            newMessages.push({
                                type: msgType,
                                text: response.message,
                                products: products.length > 0 ? products : undefined,
                                variantProduct,
                                variants: availableVariants.length > 0 ? availableVariants : undefined,
                                quantity,
                                sender: 'assistant',
                                actionData
                            });
                        } catch (e) {
                            console.error("Error parsing action:", e);
                        }
                    }
                    // Sync cart after potential cart actions
                    await refreshCart();
                }

                if (newMessages.length === 0) {
                    newMessages.push({ type: 'text', text: response.message, sender: 'assistant' });
                }
                // When user demands a new product (new variant selection), replace old variant
                // bubbles so the new product's variants are shown (user moved on from previous)
                const hasNewVariant = newMessages.some((m) => m.type === 'variant');
                setChatMessages((prev: ChatMessage[]) => {
                    const base = hasNewVariant ? prev.filter((m) => m.type !== 'variant') : prev;
                    return [...base, ...newMessages];
                });
            } else {
                const emotion = response.emotion ?? 'upset';
                if (emotion === 'happy') setAvatarState('success');
                else if (emotion === 'normal') setAvatarState('normal');
                else setAvatarState('failed');
                setChatMessages((prev: ChatMessage[]) => [...prev, { type: 'text', text: response.message, sender: 'assistant' }]);
            }
        } catch (error) {
            console.error("AI Command failed", error);
            setAvatarState('failed');
            setChatMessages((prev: ChatMessage[]) => [...prev, { type: 'text', text: "I'm sorry, I'm having trouble connecting to my brain right now.", sender: 'assistant' }]);
        } finally {
            setIsProcessing(false);
        }
    };

    const handleAddToCart = async (v: AiProductVariant, product_name: string, quantity: number) => {
        setIsProcessing(true);
        try {
            await cartService.addToCart(v.variant_id, quantity, user?.id ? parseInt(user.id) : undefined, sessionId || undefined);
            showSnackbar(`${v.variant_name} added to cart!`, 'success');

            const confirmResult = await cartService.confirmVariant({
                action: 'variant_selection',
                status: 'success',
                product_name: product_name,
                variant_id: v.variant_id,
                quantity: quantity,
                session_id: sessionId || undefined,
                customer_id: user?.id ? parseInt(user.id) : undefined
            });

            if (confirmResult.success) {
                setAvatarState('success');
                if (confirmResult.has_more && confirmResult.next_action?.action_type === 'variant_selection') {
                    const nextAction = confirmResult.next_action;
                    setChatMessages((prev: ChatMessage[]) => [...prev, {
                        type: 'variant',
                        text: confirmResult.message,
                        variantProduct: {
                            product_id: nextAction.data.product_id,
                            name: nextAction.data.product_name,
                            description: '', base_price: '0', sale_price: '0', category_id: 0, ispopular: false, stock_quantity: 0, isVisible: true, image_url: null, created_at: null, brandID: 0, price_range: '', tag: '', alert_stock: 0
                        },
                        variants: nextAction.data.available_variants,
                        quantity: nextAction.data.quantity || 1,
                        sender: 'assistant'
                    }]);
                } else {
                    setChatMessages((prev: ChatMessage[]) => [...prev, { type: 'text', text: confirmResult.message, sender: 'assistant' }]);
                }
                await refreshCart();
            }
        } catch (error) {
            setAvatarState('failed');
            showSnackbar("Failed to add to cart.", 'error');
        } finally {
            setIsProcessing(false);
        }
    };

    const handleIntroClick = () => {
        if (isIntro) {
            setIntroStep((prev: number) => prev + 1);
        }
    };

    // Helper to get current avatar source
    const getCurrentAvatar = () => {
        if (isIntro) return INTRO_PHASES[introStep].avatar;
        switch (avatarState) {
            case 'processing': return AVATAR_PROCESSING;
            case 'success': return AVATAR_SUCCEED;
            case 'failed': return AVATAR_FAILED;
            default: return AVATAR_NORMAL;
        }
    };

    const handleLogout = async () => {
        await clearCartOnLogout();
        logout();
        navigate('/login');
    };

    const handleCloseModal = () => {
        navigate('/menu');
    };

    const openGuide = () => {
        setGuideStep(0);
        setShowGuide(true);
    };

    const closeGuide = () => {
        setShowGuide(false);
    };

    const goGuideNext = () => {
        if (guideAnimating || guideStep >= GUIDE_STEPS.length - 1) return;
        setGuideDirection('next');
        setGuideAnimating(true);
        setTimeout(() => {
            setGuideStep(s => s + 1);
            setGuideAnimating(false);
        }, 300);
    };

    const goGuidePrev = () => {
        if (guideAnimating || guideStep <= 0) return;
        setGuideDirection('prev');
        setGuideAnimating(true);
        setTimeout(() => {
            setGuideStep(s => s - 1);
            setGuideAnimating(false);
        }, 300);
    };

    return (
        <div className={`order-assistant-container ${isPortrait ? 'portrait-mode' : 'landscape-mode'}`}>
            <div className="background-blur"></div>

            {/* Top Right Actions */}
            {!isIntro && (
                <div className="top-right-actions">
                    <button className={`help-guide-btn ${helpButtonShake ? 'help-guide-btn-shake' : ''}`} onClick={openGuide} title="How to use">
                        <svg viewBox="0 0 24 24" fill="none" className="btn-icon">
                            <circle cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="2.5" />
                            <path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" />
                            <circle cx="12" cy="17" r="0.5" fill="currentColor" stroke="currentColor" strokeWidth="1.5" />
                        </svg>
                        <span>Help</span>
                    </button>
                    <button className="explore-menu-btn" onClick={() => navigate('/menu')}>
                        <span>Explore Menu</span>
                        <svg viewBox="0 0 24 24" fill="none" className="btn-icon">
                            <path d="M4 6H20" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" />
                            <path d="M4 12H20" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" />
                            <path d="M4 18H20" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" />
                        </svg>
                    </button>
                </div>
            )}

            {/* Help Guide Overlay */}
            {showGuide && (
                <div className="guide-overlay" onClick={(e) => e.target === e.currentTarget && closeGuide()}>
                    <div className="guide-popup">
                        {/* Close Button */}
                        <button className="guide-close-btn" onClick={closeGuide} title="Close">
                            <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                                <path d="M18 6L6 18M6 6l12 12" />
                            </svg>
                        </button>

                        {/* Step Counter */}
                        <div className="guide-step-counter">
                            {guideStep + 1} / {GUIDE_STEPS.length}
                        </div>

                        {/* Content */}
                        <div className={`guide-slide ${guideAnimating ? `slide-out-${guideDirection}` : 'slide-in'}`}>
                            {/* Avatar */}
                            <div className="guide-avatar-wrap" style={{ '--guide-accent': GUIDE_STEPS[guideStep].accent } as React.CSSProperties}>
                                <div className="guide-avatar-glow"></div>
                                <img
                                    src={GUIDE_STEPS[guideStep].avatar}
                                    alt="Guide Avatar"
                                    className="guide-avatar-img"
                                />
                            </div>

                            {/* Text */}
                            <div className="guide-text-block">
                                <h2 className="guide-title">{GUIDE_STEPS[guideStep].title}</h2>
                                <p className="guide-description">{GUIDE_STEPS[guideStep].description}</p>
                                {GUIDE_STEPS[guideStep].tip && (
                                    <div className="guide-tip">
                                        <span className="guide-tip-label">Try saying:</span>
                                        <span className="guide-tip-text">"{GUIDE_STEPS[guideStep].tip}"</span>
                                    </div>
                                )}
                            </div>
                        </div>

                        {/* Progress Dots */}
                        <div className="guide-dots">
                            {GUIDE_STEPS.map((_, i) => (
                                <button
                                    key={i}
                                    className={`guide-dot ${i === guideStep ? 'active' : ''}`}
                                    onClick={() => {
                                        if (i === guideStep || guideAnimating) return;
                                        setGuideDirection(i > guideStep ? 'next' : 'prev');
                                        setGuideAnimating(true);
                                        setTimeout(() => { setGuideStep(i); setGuideAnimating(false); }, 300);
                                    }}
                                    style={i === guideStep ? { '--guide-accent': GUIDE_STEPS[i].accent } as React.CSSProperties : {}}
                                />
                            ))}
                        </div>

                        {/* Navigation */}
                        <div className="guide-nav">
                            <button
                                className="guide-nav-btn prev"
                                onClick={goGuidePrev}
                                disabled={guideStep === 0}
                            >
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                                    <polyline points="15 18 9 12 15 6" />
                                </svg>
                                Back
                            </button>

                            {guideStep < GUIDE_STEPS.length - 1 ? (
                                <button className="guide-nav-btn next primary" onClick={goGuideNext}>
                                    Next
                                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                                        <polyline points="9 18 15 12 9 6" />
                                    </svg>
                                </button>
                            ) : (
                                <button className="guide-nav-btn next primary done" onClick={closeGuide}>
                                    Got it!
                                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                                        <polyline points="20 6 9 17 4 12" />
                                    </svg>
                                </button>
                            )}
                        </div>
                    </div>
                </div>
            )}

            {isIntro ? (
                // INTRO OVERLAY
                <div className="intro-overlay" onClick={handleIntroClick}>
                    <div className="intro-content-centered">
                        <div className="speech-bubble intro-bubble">
                            <p>{INTRO_PHASES[introStep].text}</p>
                            <div className="bubble-arrow-down"></div>
                        </div>
                        <div className="avatar-container-intro">
                            <img src={getCurrentAvatar()} className="avatar-img-large" alt="AI Agent" />
                        </div>
                        <div className="tap-hint">Tap to continue</div>
                    </div>
                </div>
            ) : (
                // MAIN LAYOUT
                <div className="main-layout-wrapper">
                    {/* Chat Container (Left in Landscape, Bottom in Portrait) */}
                    <div className="chat-interface-container smart-container">
                        <div className="smart-header">
                            <span className="smart-title">Assistant Chat</span>
                        </div>
                        <div className="smart-content">
                            <div className="instructions-mini-container">
                                <span className="instructions-label">Try:</span>
                                {['add rice', 'select rice', 'show cart', 'checkout'].map((cmd) => (
                                    <button
                                        key={cmd}
                                        type="button"
                                        className="instruction-chip"
                                        onClick={() => handleSendChat(cmd)}
                                        disabled={isProcessing}
                                    >
                                        {cmd}
                                    </button>
                                ))}
                            </div>
                            <div className="chat-mode">
                                <div className="chat-history">
                                    {chatMessages.map((msg: ChatMessage, i: number) => (
                                        <div key={i} className={`chat-message-wrapper ${msg.sender}`}>
                                            {msg.type === 'text' && (
                                                <div className={`chat-bubble ${msg.sender}`}>{msg.text}</div>
                                            )}
                                            {msg.type === 'products' && (
                                                <div className="products-bubble-container">
                                                    {msg.text && <div className="bubble-instruction">{msg.text}</div>}
                                                    <div className="products-slider">
                                                        {msg.products?.map((product: Product) => (
                                                            <div key={product.product_id} className="slider-item">
                                                                <ProductCard product={product} onExpand={() => { }} />
                                                            </div>
                                                        ))}
                                                    </div>
                                                </div>
                                            )}
                                            {msg.type === 'variant' && msg.variantProduct && (
                                                <div className="variant-bubble">
                                                    <div className="variant-card-header">
                                                        <h4>{msg.variantProduct.name}</h4>
                                                        <span>Select Option</span>
                                                    </div>
                                                    <div className="variant-list-mini">
                                                        {msg.variants?.map((v: AiProductVariant) => (
                                                            <div key={v.variant_id} className="variant-item-mini">
                                                                <div className="v-info">
                                                                    <span className="v-name">{v.variant_name}</span>
                                                                    <span className="v-stock">Stock: {v.stock} ({v.variant_id})</span>
                                                                </div>
                                                                <div className="v-price">Rs. {v.sell_price}</div>
                                                                <button
                                                                    className="v-add-btn"
                                                                    onClick={() => handleAddToCart(v, msg.variantProduct!.name, msg.quantity || 1)}
                                                                    disabled={isProcessing}
                                                                >
                                                                    Add
                                                                </button>
                                                            </div>
                                                        ))}
                                                    </div>
                                                </div>
                                            )}
                                            {msg.type === 'cart_action' && msg.actionData && (
                                                <div className="cart-action-bubble">
                                                    <div className="cart-action-icon" style={{ backgroundColor: msg.actionData.variant_id ? 'var(--color-success)' : 'var(--color-danger)' }}>
                                                        {msg.actionData.quantity > 0 ? '+' : '-'}
                                                    </div>
                                                    <div className="cart-action-details">
                                                        <span className="action-title">{msg.actionData.quantity > 0 ? 'Added' : 'Removed'}</span>
                                                        <span className="action-item">{msg.actionData.quantity > 0 ? msg.actionData.quantity : ''} {msg.actionData.product_name}</span>
                                                    </div>
                                                </div>
                                            )}
                                            {msg.type === 'bill' && msg.actionData && (
                                                <div className="bill-bubble">
                                                    <div className="bill-header"><h3>Order Summary</h3></div>
                                                    <div className="bill-items">
                                                        {msg.actionData.cartItems?.map((item: any, idx: number) => (
                                                            <div key={idx} className="bill-item">
                                                                <span>{item.quantity}x {item.product_name}</span>
                                                                <span>Rs. {(item.sell_price * item.quantity).toFixed(2)}</span>
                                                            </div>
                                                        ))}
                                                    </div>
                                                    <div className="bill-total">
                                                        <span>Total</span>
                                                        <span className="total-price">Rs. {msg.actionData.subtotal?.toFixed(2)}</span>
                                                    </div>
                                                    <button className="bill-checkout-btn" onClick={() => navigate('/checkout')}>Checkout</button>
                                                </div>
                                            )}
                                            {msg.type === 'cart_view' && msg.actionData && (
                                                <div className="cart-view-bubble">
                                                    <div className="cart-view-header">
                                                        <span>Your Cart ({msg.actionData.total_items})</span>
                                                    </div>
                                                    <div className="cart-view-list">
                                                        {msg.actionData.cartItems?.map((item: any, idx: number) => (
                                                            <div key={idx} className="cart-view-item">
                                                                <span>{item.quantity}x {item.product_name}</span>
                                                                <span className="item-price">Rs. {(item.sell_price * item.quantity).toFixed(2)}</span>
                                                            </div>
                                                        ))}
                                                    </div>
                                                    <div className="cart-view-footer">
                                                        <span>Subtotal: Rs. {msg.actionData.subtotal?.toFixed(2)}</span>
                                                    </div>
                                                    <button className="cart-view-checkout-btn" onClick={() => navigate('/checkout')}>
                                                        Checkout
                                                    </button>
                                                </div>
                                            )}
                                        </div>
                                    ))}
                                    <div ref={chatEndRef} />
                                </div>
                                <div className="chat-input-area">
                                    <div className="input-actions-left">
                                        {/* <button className="action-icon-btn cart-bubble-btn" onClick={() => navigate('/menu')}>
                                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                                                <circle cx="9" cy="21" r="1" />
                                                <circle cx="20" cy="21" r="1" />
                                                <path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6" />
                                            </svg>
                                            {cartCount > 0 && <span className="cart-badge">{cartCount}</span>}
                                        </button> */}
                                        {/* <button className="action-icon-btn" onClick={() => inputRef.current?.focus()}>
                                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3">
                                                <rect x="2" y="4" width="20" height="16" rx="2" />
                                                <path d="M6 8H8" /><path d="M11 8H13" /><path d="M16 8H18" />
                                                <path d="M6 12H18" /><path d="M8 16H16" />
                                            </svg>
                                        </button> */}
                                    </div>
                                    <input
                                        ref={inputRef}
                                        type="text"
                                        placeholder="Type your order..."
                                        value={chatInput}
                                        onChange={(e) => setChatInput(e.target.value)}
                                        onKeyPress={(e) => e.key === 'Enter' && handleSendChat()}
                                    />
                                    <button className="send-btn" onClick={() => handleSendChat()}>
                                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
                                            <line x1="22" y1="2" x2="11" y2="13"></line>
                                            <polygon points="22 2 15 22 11 13 2 9 22 2"></polygon>
                                        </svg>
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* Avatar Container (Right in Landscape, Top in Portrait) */}
                    <div className="avatar-side-container">
                        <div className={`avatar-wrapper ${avatarState}`}>
                            <img src={getCurrentAvatar()} className="avatar-img-main" alt="Agent" />
                        </div>
                    </div>
                </div>
            )}

            {showSuccessModal && (
                <SuccessModal
                    orderId={lastOrderId}
                    isLoggedIn={user?.userType === 'authenticated'}
                    onLogout={handleLogout}
                    onClose={handleCloseModal}
                />
            )}
        </div>
    );
};

export default OrderAssistant;
