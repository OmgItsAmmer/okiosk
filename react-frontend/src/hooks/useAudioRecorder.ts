import { useState, useRef, useCallback, useEffect } from 'react';

interface UseAudioRecorderReturn {
    isRecording: boolean;
    isSupported: boolean;
    startRecording: () => Promise<void>;
    stopRecording: () => Promise<Blob | null>;
    error: string | null;
    recordingDuration: number;
}

/**
 * Custom hook for browser-native audio recording
 * Uses getUserMedia and MediaRecorder APIs
 * 
 * @param maxDurationMs - Maximum recording duration in milliseconds (default: 5000)
 * @returns Recording controls and state
 */
export function useAudioRecorder(maxDurationMs: number = 5000): UseAudioRecorderReturn {
    const [isRecording, setIsRecording] = useState(false);
    const [isSupported, setIsSupported] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [recordingDuration, setRecordingDuration] = useState(0);

    const mediaRecorderRef = useRef<MediaRecorder | null>(null);
    const streamRef = useRef<MediaStream | null>(null);
    const chunksRef = useRef<Blob[]>([]);
    const maxDurationTimeoutRef = useRef<NodeJS.Timeout | null>(null);
    const durationIntervalRef = useRef<NodeJS.Timeout | null>(null);
    const startTimeRef = useRef<number>(0);
    const stopResolveRef = useRef<((blob: Blob | null) => void) | null>(null);

    // Check browser support on mount
    useEffect(() => {
        const hasGetUserMedia = !!(navigator.mediaDevices && navigator.mediaDevices.getUserMedia);
        const hasMediaRecorder = typeof MediaRecorder !== 'undefined';
        setIsSupported(hasGetUserMedia && hasMediaRecorder);

        if (!hasGetUserMedia || !hasMediaRecorder) {
            setError('Audio recording is not supported in this browser');
        }
    }, []);

    // Cleanup on unmount
    useEffect(() => {
        return () => {
            if (maxDurationTimeoutRef.current) {
                clearTimeout(maxDurationTimeoutRef.current);
            }
            if (durationIntervalRef.current) {
                clearInterval(durationIntervalRef.current);
            }
            if (streamRef.current) {
                streamRef.current.getTracks().forEach(track => track.stop());
            }
        };
    }, []);

    const startRecording = useCallback(async () => {
        if (!isSupported) {
            setError('Audio recording is not supported');
            return;
        }

        try {
            setError(null);
            chunksRef.current = [];
            setRecordingDuration(0);

            // Request microphone access with mono audio
            const stream = await navigator.mediaDevices.getUserMedia({
                audio: {
                    channelCount: 1,          // Mono audio
                    sampleRate: 16000,        // 16kHz preferred for Whisper
                    echoCancellation: true,   // Reduce echo
                    noiseSuppression: true,   // Reduce background noise
                },
            });

            streamRef.current = stream;

            // Create MediaRecorder with WebM format (widely supported)
            const mimeType = MediaRecorder.isTypeSupported('audio/webm;codecs=opus')
                ? 'audio/webm;codecs=opus'
                : MediaRecorder.isTypeSupported('audio/webm')
                    ? 'audio/webm'
                    : 'audio/mp4';

            const mediaRecorder = new MediaRecorder(stream, {
                mimeType,
                audioBitsPerSecond: 64000, // Lower bitrate for smaller files
            });

            mediaRecorderRef.current = mediaRecorder;

            // Collect audio data chunks
            mediaRecorder.ondataavailable = (event) => {
                if (event.data.size > 0) {
                    chunksRef.current.push(event.data);
                }
            };

            // Handle recording stop
            mediaRecorder.onstop = () => {
                // Clear timers
                if (maxDurationTimeoutRef.current) {
                    clearTimeout(maxDurationTimeoutRef.current);
                    maxDurationTimeoutRef.current = null;
                }
                if (durationIntervalRef.current) {
                    clearInterval(durationIntervalRef.current);
                    durationIntervalRef.current = null;
                }

                // Stop all tracks
                if (streamRef.current) {
                    streamRef.current.getTracks().forEach(track => track.stop());
                    streamRef.current = null;
                }

                setIsRecording(false);

                // Create blob from chunks
                const blob = chunksRef.current.length > 0
                    ? new Blob(chunksRef.current, { type: mimeType })
                    : null;

                // Resolve the promise from stopRecording
                if (stopResolveRef.current) {
                    stopResolveRef.current(blob);
                    stopResolveRef.current = null;
                }
            };

            mediaRecorder.onerror = (event) => {
                console.error('MediaRecorder error:', event);
                setError('Recording failed');
                setIsRecording(false);
            };

            // Start recording
            mediaRecorder.start(100); // Collect data every 100ms
            startTimeRef.current = Date.now();
            setIsRecording(true);

            // Update duration display
            durationIntervalRef.current = setInterval(() => {
                setRecordingDuration(Date.now() - startTimeRef.current);
            }, 100);

            // Auto-stop after max duration
            maxDurationTimeoutRef.current = setTimeout(() => {
                if (mediaRecorderRef.current?.state === 'recording') {
                    console.log('Auto-stopping recording after max duration');
                    mediaRecorderRef.current.stop();
                }
            }, maxDurationMs);

        } catch (err) {
            console.error('Failed to start recording:', err);
            if (err instanceof Error) {
                if (err.name === 'NotAllowedError') {
                    setError('Microphone access denied. Please allow microphone access.');
                } else if (err.name === 'NotFoundError') {
                    setError('No microphone found. Please connect a microphone.');
                } else {
                    setError(`Recording failed: ${err.message}`);
                }
            } else {
                setError('Failed to start recording');
            }
            setIsRecording(false);
        }
    }, [isSupported, maxDurationMs]);

    const stopRecording = useCallback((): Promise<Blob | null> => {
        return new Promise((resolve) => {
            if (!mediaRecorderRef.current || mediaRecorderRef.current.state !== 'recording') {
                resolve(null);
                return;
            }

            // Store resolve function to be called in onstop handler
            stopResolveRef.current = resolve;
            mediaRecorderRef.current.stop();
        });
    }, []);

    return {
        isRecording,
        isSupported,
        startRecording,
        stopRecording,
        error,
        recordingDuration,
    };
}

export default useAudioRecorder;
