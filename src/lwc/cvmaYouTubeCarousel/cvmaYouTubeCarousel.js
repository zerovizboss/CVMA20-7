import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFeaturedVideos from '@salesforce/apex/CVMAYouTubeCarouselController.getFeaturedVideos';
import getVideosByCategory from '@salesforce/apex/CVMAYouTubeCarouselController.getVideosByCategory';
import getVideoCategories from '@salesforce/apex/CVMAYouTubeCarouselController.getVideoCategories';
import trackVideoView from '@salesforce/apex/CVMAYouTubeCarouselController.trackVideoView';

export default class CvmaYouTubeCarousel extends LightningElement {
    // Public API properties
    @api carouselHeight = '500px';
    @api autoplay = false;
    @api showThumbnails; // Default to true in connectedCallback
    @api featuredOnly; // Default to true in connectedCallback
    @api categoryFilter = ''; // Filter by category

    // Track properties
    @track currentVideoIndex = 0;
    @track featuredVideos = [];
    @track allVideos = [];
    @track categories = [];
    @track selectedCategory = '';
    @track isLoading = true;
    @track error;
    @track isPlaying = false;
    @track isMuted = true;
    @track youtubeApiLoaded = false;
    @track player;

    // Computed properties
    get videos() {
        const videoList = this.featuredOnly ? this.featuredVideos : this.allVideos;
        return videoList.map((video, index) => ({
            ...video,
            isCurrentVideo: index === this.currentVideoIndex
        }));
    }

    get currentVideo() {
        return this.videos.length > 0 ? this.videos[this.currentVideoIndex] : null;
    }

    get hasPreviousVideo() {
        return this.currentVideoIndex > 0;
    }

    get hasNextVideo() {
        return this.currentVideoIndex < this.videos.length - 1;
    }

    get hasNoPreviousVideo() {
        return !this.hasPreviousVideo;
    }

    get hasNoNextVideo() {
        return !this.hasNextVideo;
    }

    get carouselStyle() {
        return `height: ${this.carouselHeight}`;
    }

    get hasVideos() {
        return this.videos && this.videos.length > 0;
    }

    get videoCount() {
        return this.videos ? this.videos.length : 0;
    }

    get currentPosition() {
        return this.currentVideoIndex + 1;
    }

    // Wire to get featured videos
    @wire(getFeaturedVideos)
    wiredFeaturedVideos({ error, data }) {
        if (data) {
            this.featuredVideos = data;
            this.isLoading = false;
            this.error = undefined;

            // Load YouTube API after data is loaded
            if (!this.youtubeApiLoaded) {
                this.loadYouTubeAPI();
            }
        } else if (error) {
            this.error = error;
            this.featuredVideos = [];
            this.isLoading = false;
            this.showToast('Error', 'Error loading videos: ' + error.body.message, 'error');
        }
    }

    // Wire to get categories
    @wire(getVideoCategories)
    wiredCategories({ error, data }) {
        if (data) {
            this.categories = data.map(cat => ({ label: cat, value: cat }));
            this.categories.unshift({ label: 'All Categories', value: '' });
        } else if (error) {
            console.error('Error loading categories:', error);
        }
    }

    // Lifecycle hooks
    connectedCallback() {
        // Set default values for boolean properties
        if (this.showThumbnails === undefined) {
            this.showThumbnails = true;
        }
        if (this.featuredOnly === undefined) {
            this.featuredOnly = true;
        }

        // Load all videos if not featured only
        if (!this.featuredOnly) {
            this.loadVideosByCategory(this.categoryFilter);
        }
    }

    renderedCallback() {
        // Initialize player after component renders
        if (this.youtubeApiLoaded && this.currentVideo && !this.player) {
            this.initializePlayer();
        }
    }

    // Load YouTube IFrame API
    loadYouTubeAPI() {
        if (this.youtubeApiLoaded) {
            return;
        }

        const script = document.createElement('script');
        script.src = 'https://www.youtube.com/iframe_api';
        script.async = true;
        document.body.appendChild(script);

        // YouTube API will call onYouTubeIframeAPIReady when loaded
        window.onYouTubeIframeAPIReady = () => {
            this.youtubeApiLoaded = true;
            this.initializePlayer();
        };
    }

    // Initialize YouTube player
    initializePlayer() {
        if (!this.currentVideo) {
            return;
        }

        const playerElement = this.template.querySelector('.youtube-player');
        if (!playerElement) {
            return;
        }

        try {
            this.player = new YT.Player(playerElement, {
                height: '100%',
                width: '100%',
                videoId: this.currentVideo.videoId,
                playerVars: {
                    autoplay: this.autoplay ? 1 : 0,
                    mute: this.isMuted ? 1 : 0,
                    controls: 1,
                    rel: 0, // Don't show related videos from other channels
                    modestbranding: 1, // Minimal YouTube branding
                    fs: 1, // Allow fullscreen
                    cc_load_policy: 1 // Show closed captions by default
                },
                events: {
                    'onStateChange': this.onPlayerStateChange.bind(this)
                }
            });

            // Track video view
            this.trackView(this.currentVideo.videoId);

        } catch (error) {
            console.error('Error initializing YouTube player:', error);
        }
    }

    // Player state change handler
    onPlayerStateChange(event) {
        if (event.data === YT.PlayerState.PLAYING) {
            this.isPlaying = true;
        } else if (event.data === YT.PlayerState.PAUSED || event.data === YT.PlayerState.ENDED) {
            this.isPlaying = false;
        }

        // Auto-advance to next video when current video ends
        if (event.data === YT.PlayerState.ENDED && this.hasNextVideo) {
            setTimeout(() => {
                this.handleNext();
            }, 2000); // 2 second delay before auto-advance
        }
    }

    // Navigation handlers
    handlePrevious() {
        if (this.hasPreviousVideo) {
            this.currentVideoIndex--;
            this.changeVideo();
        }
    }

    handleNext() {
        if (this.hasNextVideo) {
            this.currentVideoIndex++;
            this.changeVideo();
        }
    }

    handleThumbnailClick(event) {
        const index = parseInt(event.currentTarget.dataset.index, 10);
        this.currentVideoIndex = index;
        this.changeVideo();
    }

    // Change video
    changeVideo() {
        if (this.player && this.currentVideo) {
            this.player.loadVideoById(this.currentVideo.videoId);
            this.trackView(this.currentVideo.videoId);
        }
    }

    // Playback control handlers
    handlePlayPause() {
        if (!this.player) {
            return;
        }

        if (this.isPlaying) {
            this.player.pauseVideo();
        } else {
            this.player.playVideo();
        }
    }

    handleMuteToggle() {
        if (!this.player) {
            return;
        }

        if (this.isMuted) {
            this.player.unMute();
            this.isMuted = false;
        } else {
            this.player.mute();
            this.isMuted = true;
        }
    }

    // Category filter handler
    handleCategoryChange(event) {
        this.selectedCategory = event.detail.value;
        this.loadVideosByCategory(this.selectedCategory);
    }

    // Load videos by category
    loadVideosByCategory(category) {
        this.isLoading = true;
        getVideosByCategory({ category: category })
            .then(result => {
                this.allVideos = result;
                this.currentVideoIndex = 0;
                this.isLoading = false;
                this.error = undefined;

                // Reload player with new video
                if (this.player) {
                    this.changeVideo();
                }
            })
            .catch(error => {
                this.error = error;
                this.isLoading = false;
                this.showToast('Error', 'Error loading videos: ' + error.body.message, 'error');
            });
    }

    // Track video view
    trackView(videoId) {
        trackVideoView({ videoId: videoId })
            .then(() => {
                // View tracked successfully
            })
            .catch(error => {
                // Silently fail - don't disrupt user experience
                console.error('Error tracking video view:', error);
            });
    }

    // Show toast message
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}
