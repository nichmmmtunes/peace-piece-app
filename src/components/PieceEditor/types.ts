export interface VideoClip {
  id: string;
  file?: File; // Make file optional since it won't be available after page reload
  url?: string;
  duration: number;
  contentStartTime: number; // Start point within the original media file
  contentEndTime: number; // End point within the original media file
  layer: number;
  timelineStart: number;
  timelineEnd: number;
  name: string;
  type: 'video' | 'audio' | 'image' | 'text';
  icon: string;
  content?: string; // For text layers
  
  // Transform properties
  position?: { x: number; y: number }; // Percentage of canvas (0-100)
  scale?: { x: number; y: number }; // Percentage of canvas dimensions (0-100)
  rotation?: number; // Degrees
  opacity?: number; // 0-1
  
  // Text properties
  fontSize?: number; // Percentage of canvas width (0-20)
  fontFamily?: string;
  fontWeight?: string;
  fontStyle?: string;
  textAlign?: 'left' | 'center' | 'right' | 'justify';
  textColor?: string;
  textShadow?: string;
  lineHeight?: number;
  letterSpacing?: number;
  
  // Media properties
  volume?: number;
  playbackRate?: number;
  brightness?: number;
  contrast?: number;
  saturation?: number;
  blur?: number;
  
  // Animation properties
  animation?: string;
  animationDuration?: number;
  animationDelay?: number;
  
  // Blending properties
  mixBlendMode?: string;
  
  sampleData?: {
    type: string;
    thumbnail?: string;
    description?: string;
    position?: { x: number; y: number };
    size?: { width: number; height: number };
    opacity?: number;
    fontSize?: number;
    fontFamily?: string;
    color?: string;
    textAlign?: string;
    fontWeight?: string;
    textShadow?: string;
    animation?: string;
    title?: string;
    artist?: string;
    waveform?: number[];
    volume?: number;
  };
}