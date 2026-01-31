import React, { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import './OrderAssistant.css';
import { useAudioRecorder } from '../hooks/useAudioRecorder';
import { transcribeAudio } from '../services/transcribeService';
import ProductCard from '../components/ProductCard';
import { useAuth } from '../hooks/useAuth';
import { sendAiCommand } from '../services/aiService';
import type { Product } from '../types/menu';
import { colors } from '../constants/colors';
import { useSnackbar } from '../components/Snackbar';
import * as cartService from '../services/cartService';

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

const OrderAssistant: React.FC = () => {
    const navigate = useNavigate();
    const [volume, setVolume] = useState(70);
    const [isMuted, setIsMuted] = useState(false);
    const [message, setMessage] = useState("I can help you with your order.");
    const [isProcessing, setIsProcessing] = useState(false);
    const [chatInput, setChatInput] = useState("");
    const [chatMessages, setChatMessages] = useState<ChatMessage[]>([
        { type: 'text', text: "Hello! How can I help you today?", sender: 'assistant' }
    ]);

    const { showSnackbar } = useSnackbar();

    const chatEndRef = useRef<HTMLDivElement>(null);

    const scrollToBottom = () => {
        chatEndRef.current?.scrollIntoView({ behavior: "smooth" });
    };

    useEffect(() => {
        scrollToBottom();
    }, [chatMessages]);

    // Audio recorder hook (max 5 seconds)
    const {
        isRecording,
        isSupported,
        startRecording,
        stopRecording,
        error: recorderError
    } = useAudioRecorder(5000);

    const handleVoiceToggle = async () => {
        if (isProcessing) return;

        if (!isRecording) {
            await startRecording();
            setMessage("Listening...");
        } else {
            const audioBlob = await stopRecording();

            if (audioBlob) {
                setIsProcessing(true);
                setMessage("Thinking...");

                try {
                    const response = await transcribeAudio(audioBlob);
                    setMessage(`"${response.text}"`);
                    console.log("Transcribed text:", response.text);
                    // Automatically send transcribed text to AI chat
                    handleSendChat(response.text);
                } catch (err) {
                    console.error("Transcription failed:", err);
                    setMessage("Sorry, I didn't catch that.");
                } finally {
                    setIsProcessing(false);
                }
            }
        }
    };

    const handleVolumeChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const newVolume = parseInt(e.target.value);
        setVolume(newVolume);
        if (newVolume > 0 && isMuted) {
            setIsMuted(false);
        }
    };

    const toggleMute = () => {
        setIsMuted(!isMuted);
    };

    const { user, sessionId } = useAuth();

    const handleSendChat = async (overrideMsg?: string) => {
        const textToSend = overrideMsg || chatInput;
        if (!textToSend.trim()) return;

        // 1. Add user message to UI
        if (!overrideMsg) {
            setChatMessages(prev => [...prev, { type: 'text', text: textToSend, sender: 'user' }]);
            setChatInput("");
        }

        setIsProcessing(true);

        try {
            // 2. Call backend
            const response = await sendAiCommand({
                prompt: textToSend,
                session_id: sessionId || undefined,
                customer_id: user?.id ? parseInt(user.id) : undefined
            });

            if (response.success) {
                // We'll collect multiple messages if multiple actions are executed
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
                                // For bill we might need to fetch latest cart data
                                const cartData = await cartService.getCart(user?.id ? parseInt(user.id) : undefined, sessionId || undefined);
                                actionData = { ...data, cartItems: cartData.items, subtotal: cartData.subtotal, total_items: cartData.total_items };
                            } else if (actionType === 'view_cart') {
                                msgType = 'cart_view';
                                const cartData = await cartService.getCart(user?.id ? parseInt(user.id) : undefined, sessionId || undefined);
                                actionData = { ...data, cartItems: cartData.items, subtotal: cartData.subtotal, total_items: cartData.total_items };
                            } else if (actionType === 'checkout') {
                                msgType = 'checkout';
                                const cartData = await cartService.getCart(user?.id ? parseInt(user.id) : undefined, sessionId || undefined);
                                actionData = { ...data, cartItems: cartData.items, subtotal: cartData.subtotal };
                            }

                            newMessages.push({
                                type: msgType,
                                text: response.message, // Use common response message for now
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

                // If no special action bubbles were created, add a simple text response
                if (newMessages.length === 0) {
                    newMessages.push({
                        type: 'text',
                        text: response.message,
                        sender: 'assistant'
                    });
                }

                setChatMessages(prev => [...prev, ...newMessages]);
                setMessage(response.message);
            } else {
                setChatMessages(prev => [...prev, {
                    type: 'text',
                    text: response.message,
                    sender: 'assistant'
                }]);
                setMessage(response.message);
            }
        } catch (error) {
            console.error("AI Command failed", error);
            setChatMessages(prev => [...prev, {
                type: 'text',
                text: "I'm sorry, I'm having trouble connecting to my brain right now.",
                sender: 'assistant'
            }]);
        } finally {
            setIsProcessing(false);
        }
    };


    const handleAddToCart = async (v: AiProductVariant, product_name: string, quantity: number) => {
        setIsProcessing(true);
        try {
            // 1. Add to cart
            await cartService.addToCart(
                v.variant_id,
                quantity,
                user?.id ? parseInt(user.id) : undefined,
                sessionId || undefined
            );

            showSnackbar(`${v.variant_name} added to cart!`, 'success');

            // 2. Confirm to AI to handle next item in queue
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
                if (confirmResult.has_more && confirmResult.next_action) {
                    // Start next variant selection
                    const nextAction = confirmResult.next_action;
                    if (nextAction.action_type === 'variant_selection') {
                        const nextVariantProduct: Product = {
                            product_id: nextAction.data.product_id,
                            name: nextAction.data.product_name,
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

                        setChatMessages(prev => [...prev, {
                            type: 'variant',
                            text: confirmResult.message,
                            variantProduct: nextVariantProduct,
                            variants: nextAction.data.available_variants,
                            quantity: nextAction.data.quantity || 1,
                            sender: 'assistant'
                        }]);
                        setMessage(confirmResult.message);
                    }
                } else {
                    // All done
                    setChatMessages(prev => [...prev, {
                        type: 'text',
                        text: confirmResult.message,
                        sender: 'assistant'
                    }]);
                    setMessage(confirmResult.message);
                }
            }
        } catch (error) {
            console.error("Failed to add to cart", error);
            showSnackbar("Failed to add to cart.", 'error');
        } finally {
            setIsProcessing(false);
        }
    };

    useEffect(() => {
        if (recorderError) {
            setMessage(`Error: ${recorderError}`);
        }
    }, [recorderError]);

    return (
        <div className="order-assistant-container" style={{ backgroundColor: colors.light.background }}>
            {/* Background blur effect */}
            <div className="background-blur"></div>

            <div className="main-layout">
                {/* Left Side: Assistant & Smart Container */}
                <div className="content-side">
                    {/* Top Section: Assistant Content */}
                    <div className="assistant-content-top">
                        {/* Speech Bubble */}
                        <div className="speech-bubble">
                            <p>{message}</p>
                        </div>

                        {/* Avatar */}
                        <div className="avatar-container">
                            <div className={`avatar ${isRecording ? 'pulse-red' : ''} ${isProcessing ? 'pulse-blue' : ''}`}>
                                <svg
                                    viewBox="0 0 24 24"
                                    fill="none"
                                    className="avatar-icon"
                                >
                                    <path
                                        d="M12 12C14.21 12 16 10.21 16 8C16 5.79 14.21 4 12 4C9.79 4 8 5.79 8 8C8 10.21 9.79 12 12 12Z"
                                        fill="white"
                                    />
                                    <path
                                        d="M12 14C8.13 14 5 16.12 5 18.5V19C5 19.55 5.45 20 6 20H18C18.55 20 19 19.55 19 19V18.5C19 16.12 15.87 14 12 14Z"
                                        fill="white"
                                    />
                                </svg>
                            </div>
                        </div>
                    </div>

                    {/* Middle Section: Smart Container */}
                    <div className="smart-container" style={{ backgroundColor: colors.light.secondary }}>
                        <div className="smart-header">
                            <span className="smart-title">Assistant Chat</span>
                        </div>

                        <div className="smart-content">
                            <div className="chat-mode">
                                <div className="chat-history">
                                    {chatMessages.map((msg, i) => (
                                        <div key={i} className={`chat-message-wrapper ${msg.sender}`}>
                                            {msg.type === 'text' && (
                                                <div className={`chat-bubble ${msg.sender}`}>
                                                    {msg.text}
                                                </div>
                                            )}

                                            {msg.type === 'products' && (
                                                <div className="products-bubble-container">
                                                    {msg.text && <div className="bubble-instruction">{msg.text}</div>}
                                                    <div className="products-slider">
                                                        {msg.products?.map(product => (
                                                            <div key={product.product_id} className="slider-item">
                                                                <ProductCard
                                                                    product={product}
                                                                    onExpand={(p) => console.log('Expand product', p)}
                                                                />
                                                            </div>
                                                        ))}
                                                    </div>
                                                </div>
                                            )}

                                            {msg.type === 'variant' && msg.variantProduct && (
                                                <div className="variant-bubble">
                                                    <div className="variant-card-mini" style={{ borderLeft: `4px solid ${colors.light.accentYellow}` }}>
                                                        <div className="variant-card-header">
                                                            <h4>{msg.variantProduct.name}</h4>
                                                            <span>Select Option</span>
                                                        </div>
                                                        <div className="variant-list-mini">
                                                            {msg.variants?.map(v => (
                                                                <div key={v.variant_id} className="variant-item-mini">
                                                                    <div className="v-info">
                                                                        <span className="v-name">{v.variant_name}</span>
                                                                        <span className="v-stock">Stock: {v.stock}</span>
                                                                    </div>
                                                                    <div className="v-price">Rs. {v.sell_price}</div>
                                                                    <button
                                                                        className="v-add-btn"
                                                                        onClick={() => handleAddToCart(v, msg.variantProduct!.name, msg.quantity || 1)}
                                                                        disabled={isProcessing}
                                                                        style={{ backgroundColor: colors.light.primary }}
                                                                    >
                                                                        Add
                                                                    </button>
                                                                </div>
                                                            ))}
                                                        </div>
                                                    </div>
                                                </div>
                                            )}

                                            {msg.type === 'cart_action' && msg.actionData && (
                                                <div className="cart-action-bubble">
                                                    <div className="cart-action-icon" style={{ backgroundColor: msg.actionData.variant_id ? '#4CAF50' : '#FF5252' }}>
                                                        {msg.actionData.quantity > 0 ? '+' : '-'}
                                                    </div>
                                                    <div className="cart-action-details">
                                                        <span className="action-title">
                                                            {msg.actionData.quantity > 0 ? 'Added to Cart' : 'Removed from Cart'}
                                                        </span>
                                                        <span className="action-item">
                                                            {msg.actionData.quantity > 0 ? msg.actionData.quantity : ''} {msg.actionData.product_name} ({msg.actionData.variant_name})
                                                        </span>
                                                    </div>
                                                </div>
                                            )}

                                            {msg.type === 'bill' && msg.actionData && (
                                                <div className="bill-bubble">
                                                    <div className="bill-header">
                                                        <svg viewBox="0 0 24 24" className="bill-icon"><path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm0 16H5V5h14v14zM7 10h10V7H7v3zm0 4h10v-2H7v2zm0 3h10v-2H7v2z" fill="currentColor" /></svg>
                                                        <h3>Order Summary</h3>
                                                    </div>
                                                    <div className="bill-items">
                                                        {msg.actionData.cartItems?.map((item: any, idx: number) => (
                                                            <div key={idx} className="bill-item">
                                                                <span>{item.quantity}x {item.product_name}</span>
                                                                <span>Rs. {(item.sell_price * item.quantity).toFixed(2)}</span>
                                                            </div>
                                                        ))}
                                                    </div>
                                                    <div className="bill-divider"></div>
                                                    <div className="bill-total">
                                                        <span>Total Amount</span>
                                                        <span className="total-price">Rs. {msg.actionData.subtotal?.toFixed(2)}</span>
                                                    </div>
                                                    <button className="bill-checkout-btn" onClick={() => navigate('/checkout')} style={{ backgroundColor: colors.light.primary }}>
                                                        Proceed to Checkout
                                                    </button>
                                                </div>
                                            )}

                                            {msg.type === 'cart_view' && msg.actionData && (
                                                <div className="cart-view-bubble">
                                                    <div className="cart-view-header">
                                                        <span>Your Shopping Cart ({msg.actionData.total_items} items)</span>
                                                    </div>
                                                    <div className="cart-view-list">
                                                        {msg.actionData.cartItems?.map((item: any, idx: number) => (
                                                            <div key={idx} className="cart-view-item">
                                                                <div className="cart-item-info">
                                                                    <span className="item-name">{item.product_name}</span>
                                                                    <span className="item-variant">{item.variant_name}</span>
                                                                </div>
                                                                <div className="cart-item-qty">
                                                                    <span>x{item.quantity}</span>
                                                                    <span className="item-price">Rs. {item.sell_price}</span>
                                                                </div>
                                                            </div>
                                                        ))}
                                                    </div>
                                                    <div className="cart-view-footer">
                                                        <span>Subtotal: Rs. {msg.actionData.subtotal?.toFixed(2)}</span>
                                                    </div>
                                                </div>
                                            )}

                                            {msg.type === 'checkout' && msg.actionData && (
                                                <div className="checkout-bubble">
                                                    <div className="checkout-status">
                                                        <div className="status-dot animate-pulse"></div>
                                                        <span>Initiating Checkout...</span>
                                                    </div>
                                                    <div className="checkout-info">
                                                        <div className="info-row">
                                                            <span>Payment:</span>
                                                            <strong>{msg.actionData.payment_method || 'Standard'}</strong>
                                                        </div>
                                                        <div className="info-row">
                                                            <span>Shipping:</span>
                                                            <strong>{msg.actionData.shipping_method || 'Pick up'}</strong>
                                                        </div>
                                                        <div className="info-row total">
                                                            <span>Grand Total:</span>
                                                            <strong>Rs. {msg.actionData.subtotal?.toFixed(2)}</strong>
                                                        </div>
                                                    </div>
                                                    <button className="confirm-checkout-btn" style={{ backgroundColor: '#4CAF50' }}>
                                                        Confirm & Pay
                                                    </button>
                                                </div>
                                            )}
                                        </div>
                                    ))}
                                    <div ref={chatEndRef} />
                                </div>
                                <div className="chat-input-area">
                                    <input
                                        type="text"
                                        placeholder="Type a message..."
                                        value={chatInput}
                                        onChange={(e) => setChatInput(e.target.value)}
                                        onKeyPress={(e) => e.key === 'Enter' && handleSendChat()}
                                    />
                                    <button onClick={() => handleSendChat()} style={{ backgroundColor: colors.light.primary }}>
                                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                                            <path d="M22 2L11 13M22 2l-7 20-4-9-9-4 20-7z" strokeLinecap="round" strokeLinejoin="round" />
                                        </svg>
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                {/* Right Side: Controls */}
                <div className="right-controls">
                    <div className="stacked-action-buttons">
                        <button
                            className={`action-btn-mini voice-btn ${isRecording ? 'active' : ''}`}
                            aria-label="Voice"
                            onClick={handleVoiceToggle}
                            disabled={!isSupported || isProcessing}
                        >
                            <svg viewBox="0 0 24 24" fill="none" className="btn-icon">
                                <path
                                    d="M12 14C13.66 14 15 12.66 15 11V5C15 3.34 13.66 2 12 2C10.34 2 9 3.34 9 5V11C9 12.66 10.34 14 12 14Z"
                                    stroke="currentColor"
                                    strokeWidth="2"
                                    strokeLinecap="round"
                                    strokeLinejoin="round"
                                />
                                <path
                                    d="M19 11C19 14.87 15.87 18 12 18C8.13 18 5 14.87 5 11"
                                    stroke="currentColor"
                                    strokeWidth="2"
                                    strokeLinecap="round"
                                    strokeLinejoin="round"
                                />
                                <path
                                    d="M12 18V22"
                                    stroke="currentColor"
                                    strokeWidth="2"
                                    strokeLinecap="round"
                                    strokeLinejoin="round"
                                />
                            </svg>
                        </button>

                        <button className="action-btn-mini keyboard-btn" aria-label="Keyboard">
                            <svg viewBox="0 0 24 24" fill="none" className="btn-icon">
                                <rect
                                    x="2" y="4" width="20" height="16" rx="3"
                                    stroke="currentColor"
                                    strokeWidth="2"
                                />
                                <path d="M6 8H8" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
                                <path d="M11 8H13" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
                                <path d="M16 8H18" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
                                <path d="M6 12H8" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
                                <path d="M11 12H13" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
                                <path d="M16 12H18" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
                                <path d="M8 16H16" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
                            </svg>
                        </button>

                        <button
                            className="action-btn-mini menu-btn"
                            aria-label="Explore Menu"
                            onClick={() => navigate('/menu')}
                        >
                            <svg viewBox="0 0 24 24" fill="none" className="btn-icon">
                                <path d="M4 6H20" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" />
                                <path d="M4 12H20" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" />
                                <path d="M4 18H20" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" />
                            </svg>
                        </button>
                    </div>

                    {/* Volume Control */}
                    <div className="volume-control-new">
                        <button
                            className="volume-icon-btn"
                            onClick={toggleMute}
                            aria-label={isMuted ? "Unmute" : "Mute"}
                        >
                            {isMuted ? (
                                <svg viewBox="0 0 24 24" fill="none" className="volume-icon">
                                    <path d="M11 5L6 9H2V15H6L11 19V5Z" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
                                    <path d="M23 9L17 15" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
                                    <path d="M17 9L23 15" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
                                </svg>
                            ) : (
                                <svg viewBox="0 0 24 24" fill="none" className="volume-icon" style={{ color: colors.light.primary }}>
                                    <path d="M11 5L6 9H2V15H6L11 19V5Z" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
                                    <path d="M15.54 8.46C16.48 9.4 17.01 10.67 17.01 12C17.01 13.33 16.48 14.6 15.54 15.54" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
                                    <path d="M18.07 5.93C19.95 7.81 21.01 10.35 21.01 13C21.01 15.65 19.95 18.19 18.07 20.07" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
                                </svg>
                            )}
                        </button>
                        <div className="volume-slider-container-new">
                            <input
                                type="range"
                                min="0"
                                max="100"
                                value={isMuted ? 0 : volume}
                                onChange={handleVolumeChange}
                                className="volume-slider-new"
                                aria-label="Volume"
                            />
                            <div
                                className="volume-slider-fill-new"
                                style={{ height: `${isMuted ? 0 : volume}%`, backgroundColor: colors.light.accentYellow }}
                            ></div>
                        </div>
                        <span className="volume-percentage-new">{isMuted ? 0 : volume}%</span>
                    </div>
                </div>
            </div>

            {/* Help button */}
            <button className="help-btn" aria-label="Help">
                ?
            </button>
        </div>
    );
};

export default OrderAssistant;
