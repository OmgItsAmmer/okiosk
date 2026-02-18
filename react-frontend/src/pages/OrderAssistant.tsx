import React, { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import './OrderAssistant.css';
import { useAudioRecorder } from '../hooks/useAudioRecorder';
import { transcribeAudio } from '../services/transcribeService';
import ProductCard from '../components/ProductCard';
import { useAuth } from '../hooks/useAuth';
import { sendAiCommand } from '../services/aiService';
import type { Product } from '../types/menu';

import { useSnackbar } from '../components/Snackbar';
import * as cartService from '../services/cartService';
import SuccessModal from '../components/SuccessModal';

// Avatar Images
import agentNormal from '../assets/images/AIAgent/agent_normal.png';
import agentProcessing from '../assets/images/AIAgent/agent_processing.png';
import agentSucceed from '../assets/images/AIAgent/agent_succed.png';
import agentFailed from '../assets/images/AIAgent/agent_failed.png';

// Fallbacks/Mappings for requested states
const AVATAR_NORMAL = agentNormal;
const AVATAR_PROCESSING = agentProcessing;
const AVATAR_SUCCEED = agentSucceed; // Proxy for succeed.png
const AVATAR_FAILED = agentFailed;   // Proxy for agent_failed.png

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

// Intro Phases Data
const INTRO_PHASES = [
    {
        avatar: AVATAR_NORMAL,
        text: "Hey there, welcome to KK’s Online. I’m your new cashier."
    },
    {
        avatar: AVATAR_SUCCEED,
        text: "You can tell me what you want, or say things like checkout or show cart. I’ll do it—no messy menu exploration."
    },
    {
        avatar: AVATAR_NORMAL,
        text: "I’m a small kid and I can make mistakes, so please don’t get angry at me."
    }
];

const OrderAssistant: React.FC = () => {
    const navigate = useNavigate();
    const { showSnackbar } = useSnackbar();
    const { user, sessionId, logout } = useAuth(); // Added logout

    // Success Modal State
    const [showSuccessModal, setShowSuccessModal] = useState(false);
    const [lastOrderId, setLastOrderId] = useState<string | number>('');

    // Layout & Intro State
    const [isPortrait, setIsPortrait] = useState(window.innerHeight > window.innerWidth);
    const [introStep, setIntroStep] = useState(0);
    const isIntro = introStep < 3;

    // Avatar State
    const [avatarState, setAvatarState] = useState<'normal' | 'processing' | 'success' | 'failed'>('normal');

    const [isProcessing, setIsProcessing] = useState(false);
    const [chatInput, setChatInput] = useState("");
    const [chatMessages, setChatMessages] = useState<ChatMessage[]>([
        { type: 'text', text: "Hello! How can I help you today?", sender: 'assistant' }
    ]);

    const inputRef = useRef<HTMLInputElement>(null);
    const chatEndRef = useRef<HTMLDivElement>(null);

    const scrollToBottom = () => {
        chatEndRef.current?.scrollIntoView({ behavior: "smooth" });
    };

    useEffect(() => {
        scrollToBottom();
    }, [chatMessages, introStep]); // Scroll when step changes too if needed

    useEffect(() => {
        const handleResize = () => setIsPortrait(window.innerHeight > window.innerWidth);
        window.addEventListener('resize', handleResize);
        return () => window.removeEventListener('resize', handleResize);
    }, []);

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

    const {
        isRecording,
        startRecording,
        stopRecording
    } = useAudioRecorder(5000);

    const handleVoiceToggle = async () => {
        if (isProcessing || isIntro) return;

        if (!isRecording) {
            await startRecording();
            // Optional: setMessage("Listening...");
        } else {
            const audioBlob = await stopRecording();
            if (audioBlob) {
                setIsProcessing(true);
                // setMessage("Thinking...");
                try {
                    const response = await transcribeAudio(audioBlob);
                    // setMessage(`"${response.text}"`); 
                    handleSendChat(response.text);
                } catch (err) {
                    console.error("Transcription failed:", err);
                    setAvatarState('failed');
                } finally {
                    setIsProcessing(false);
                }
            }
        }
    };

    const handleSendChat = async (overrideMsg?: string) => {
        const textToSend = overrideMsg || chatInput;
        if (!textToSend.trim()) return;

        if (!overrideMsg) {
            setChatMessages(prev => [...prev, { type: 'text', text: textToSend, sender: 'user' }]);
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
                setAvatarState('success');
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
                }

                if (newMessages.length === 0) {
                    newMessages.push({ type: 'text', text: response.message, sender: 'assistant' });
                }
                setChatMessages(prev => [...prev, ...newMessages]);
            } else {
                setAvatarState('failed');
                setChatMessages(prev => [...prev, { type: 'text', text: response.message, sender: 'assistant' }]);
            }
        } catch (error) {
            console.error("AI Command failed", error);
            setAvatarState('failed');
            setChatMessages(prev => [...prev, { type: 'text', text: "I'm sorry, I'm having trouble connecting to my brain right now.", sender: 'assistant' }]);
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
                    setChatMessages(prev => [...prev, {
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
                    setChatMessages(prev => [...prev, { type: 'text', text: confirmResult.message, sender: 'assistant' }]);
                }
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
            setIntroStep(prev => prev + 1);
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

    const handleLogout = () => {
        logout();
        navigate('/login');
    };

    const handleCloseModal = () => {
        navigate('/menu');
    };

    return (
        <div className={`order-assistant-container ${isPortrait ? 'portrait-mode' : 'landscape-mode'}`}>
            <div className="background-blur"></div>

            {/* Top Right Actions */}
            {!isIntro && (
                <div className="top-right-actions">
                    <button className="explore-menu-btn" onClick={() => navigate('/menu')}>
                        <span>Explore Menu</span>
                        <svg viewBox="0 0 24 24" fill="none" className="btn-icon">
                            <path d="M4 6H20" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" />
                            <path d="M4 12H20" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" />
                            <path d="M4 18H20" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" />
                        </svg>
                    </button>
                    <button className="logout-action-btn" onClick={handleLogout} title="Logout">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="btn-icon">
                            <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path>
                            <polyline points="16 17 21 12 16 7"></polyline>
                            <line x1="21" y1="12" x2="9" y2="12"></line>
                        </svg>
                    </button>
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
                            <div className="chat-mode">
                                <div className="chat-history">
                                    {chatMessages.map((msg, i) => (
                                        <div key={i} className={`chat-message-wrapper ${msg.sender}`}>
                                            {msg.type === 'text' && (
                                                <div className={`chat-bubble ${msg.sender}`}>{msg.text}</div>
                                            )}
                                            {msg.type === 'products' && (
                                                <div className="products-bubble-container">
                                                    {msg.text && <div className="bubble-instruction">{msg.text}</div>}
                                                    <div className="products-slider">
                                                        {msg.products?.map(product => (
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
                                                        {msg.variants?.map(v => (
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
                                                    <div className="cart-view-header"><span>Your Cart ({msg.actionData.total_items})</span></div>
                                                    <div className="cart-view-list">
                                                        {msg.actionData.cartItems?.map((item: any, idx: number) => (
                                                            <div key={idx} className="cart-view-item">
                                                                <span>{item.quantity}x {item.product_name}</span>
                                                                <span className="item-price">{item.sell_price}</span>
                                                            </div>
                                                        ))}
                                                    </div>
                                                    <div className="cart-view-footer">Subtotal: Rs. {msg.actionData.subtotal?.toFixed(2)}</div>
                                                </div>
                                            )}
                                        </div>
                                    ))}
                                    <div ref={chatEndRef} />
                                </div>
                                <div className="chat-input-area">
                                    <div className="input-actions-left">
                                        <button className={`action-icon-btn ${isRecording ? 'recording' : ''}`} onClick={handleVoiceToggle}>
                                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3">
                                                <path d="M12 14C13.66 14 15 12.66 15 11V5C15 3.34 13.66 2 12 2C10.34 2 9 3.34 9 5V11C9 12.66 10.34 14 12 14Z" />
                                                <path d="M19 11C19 14.87 15.87 18 12 18C8.13 18 5 14.87 5 11" />
                                                <path d="M12 18V22" />
                                            </svg>
                                        </button>
                                        <button className="action-icon-btn" onClick={() => inputRef.current?.focus()}>
                                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3">
                                                <rect x="2" y="4" width="20" height="16" rx="2" />
                                                <path d="M6 8H8" /><path d="M11 8H13" /><path d="M16 8H18" />
                                                <path d="M6 12H18" /><path d="M8 16H16" />
                                            </svg>
                                        </button>
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
