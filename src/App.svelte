<script lang="ts">
  import { onMount } from 'svelte';
  import Router from 'svelte-spa-router';
  import { push, location } from 'svelte-spa-router';
  import { user, loading as authLoading } from './stores/authStore';
  import { supabase } from './lib/supabase';
  import Sidebar from './components/Sidebar.svelte';
  import Auth from './components/Auth.svelte';
  import Signup from './components/Signup.svelte';
  import Settings from './components/Settings.svelte';
  import Onboarding from './components/Onboarding.svelte';
  import ConfirmSignup from './components/ConfirmSignup.svelte';
  import SignupConfirmed from './components/SignupConfirmed.svelte';
  import Dashboard from './components/Dashboard.svelte';
  import Explore from './components/Explore.svelte';
  import PieceDetail from './components/PieceDetail.svelte';
  import PieceViewer from './components/PieceViewer.svelte';
  import UpdatePiece from './components/UpdatePiece.svelte';
  import PieceEditorPage from './components/PieceEditorPage.svelte';
  import Notifications from './components/Notifications.svelte';
  import ThemeToggle from './components/ThemeToggle.svelte';
  import Help from './components/Help.svelte';
  import Terms from './components/Terms.svelte';
  import Privacy from './components/Privacy.svelte';
  import Community from './components/Community.svelte';
  import PaymentPolicy from './components/PaymentPolicy.svelte';
  import Footer from './components/Footer.svelte';
  import ForgotPassword from './components/ForgotPassword.svelte';
  import ResetPassword from './components/ResetPassword.svelte';
  import Profile from './components/Profile.svelte';
  import ProfileArtist from './components/ProfileArtist.svelte';
  import ProfileOrganizer from './components/ProfileOrganizer.svelte';
  import CreatePiece from './components/CreatePiece.svelte';
  import MyPieces from './components/MyPieces.svelte';
  import ArtistProfileSettings from './components/ArtistProfileSettings.svelte';
  import OrganizerProfileSettings from './components/OrganizerProfileSettings.svelte';
  import ApplyArtist from './components/ApplyArtist.svelte';
  import ManagePiece from './components/ManagePiece.svelte';
  import ReviewApplication from './components/ReviewApplication.svelte';
  import BoltBadge from './components/BoltBadge.svelte'

  let darkMode = false;
  let onboardingCompleted = false;
  let checkingOnboarding = false;
  let initialCheckDone = false;
  let sidebarCollapsed = false;
  let isMobile = false;
  let mobileSidebarOpen = false;
  let checkingManagementAuth = false;
  let isAuthorizedToManage = false;
  let pieceToManage: any = null;
  let currentPathId: string | null = null;
  
  // New variables for update route authorization
  let checkingUpdateAuth = false;
  let isAuthorizedToUpdate = false;
  let pieceToUpdate: any = null;
  
  // New variables for edit route authorization
  let checkingEditAuth = false;
  let isAuthorizedToEdit = false;
  let pieceToEdit: any = null;
  let userArtistId: string | null = null;

  onMount(() => {
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    darkMode = prefersDark;

    // update the theme based on localStorage or system preference
    const savedDarkMode = localStorage.getItem('darkMode');
    if (savedDarkMode !== null) {
      darkMode = JSON.parse(savedDarkMode);
      updateTheme(darkMode);
    } else {
      darkMode = prefersDark;
      updateTheme(darkMode);
    }

    // Listen for system theme changes
    // window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
    //   darkMode = e.matches;
    //   updateTheme(darkMode);
    // });

    // Load sidebar state from localStorage
    const savedSidebarState = localStorage.getItem('sidebarCollapsed');
    if (savedSidebarState !== null) {
      sidebarCollapsed = JSON.parse(savedSidebarState);
    }

    // Initialize mobile detection
    isMobile = window.innerWidth <= 768;
    
    // Add resize listener for mobile detection
    const handleResize = () => {
      const wasMobile = isMobile;
      isMobile = window.innerWidth <= 768;
      
      // Close mobile sidebar if switching from mobile to desktop
      if (wasMobile && !isMobile) {
        mobileSidebarOpen = false;
      }
    };
    
    window.addEventListener('resize', handleResize);
    
    return () => {
      window.removeEventListener('resize', handleResize);
    };
  });

  function toggleDarkMode() {
    darkMode = !darkMode;
    updateTheme(darkMode);

    localStorage.setItem('darkMode', JSON.stringify(darkMode));
    if (darkMode) {
      document.documentElement.classList.add('dark-mode');
      document.documentElement.classList.remove('light-mode');
    } else {
      document.documentElement.classList.remove('dark-mode');
      document.documentElement.classList.add('light-mode');   
    }
  }

  function updateTheme(isDark: boolean) {
    if (isDark) {
      document.documentElement.classList.add('dark-mode');
      document.documentElement.classList.remove('light-mode');
      document.documentElement.style.setProperty('--bg-color', 'var(--color-primary-900)');
      document.documentElement.style.setProperty('--text-color', 'var(--color-neutral-50)');
      document.documentElement.style.setProperty('--text-muted', 'var(--color-neutral-400)');
      document.documentElement.style.setProperty('--card-bg', 'var(--color-neutral-dark-gradient)');
      document.documentElement.style.setProperty('--border-color', 'var(--color-neutral-800)');
      document.documentElement.style.setProperty('--shadow-color', 'rgba(0, 0, 0, 0.3)');
      document.documentElement.style.setProperty('--logo-gradient-stop1', '#DBDEEF');
      document.documentElement.style.setProperty('--logo-gradient-stop2', '#7E7F89');
      document.documentElement.style.setProperty('--logo-icon-color', 'var(--color-primary-400)');
    } else {
      document.documentElement.classList.remove('dark-mode');
      document.documentElement.classList.add('light-mode');
      document.documentElement.style.setProperty('--bg-color', 'var(--color-primary-00)');
      document.documentElement.style.setProperty('--text-color', 'var(--color-primary-900)');
      document.documentElement.style.setProperty('--text-muted', 'var(--color-neutral-500)');
      document.documentElement.style.setProperty('--card-bg', 'var(--color-neutral-light-gradient)');
      document.documentElement.style.setProperty('--border-color', 'var(--color-neutral-200)');
      document.documentElement.style.setProperty('--shadow-color', 'rgba(0, 0, 0, 0.05)');
      document.documentElement.style.setProperty('--logo-gradient-stop1', '#131322');
      document.documentElement.style.setProperty('--logo-gradient-stop2', '#131322');
      document.documentElement.style.setProperty('--logo-icon-color', '#131322');
    }
  }

  function toggleSidebar() {
    sidebarCollapsed = !sidebarCollapsed;
    localStorage.setItem('sidebarCollapsed', JSON.stringify(sidebarCollapsed));
  }

  function toggleMobileSidebar() {
    mobileSidebarOpen = !mobileSidebarOpen;
  }

  function closeMobileSidebar() {
    mobileSidebarOpen = false;
  }

  async function checkOnboardingStatus() {
    if (!$user) {
      checkingOnboarding = false;
      return;
    }
    
    checkingOnboarding = true;
    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('onboarding_completed')
        .eq('id', $user.id)
        .maybeSingle();
        
      if (error) throw error;
      
      // If no profile exists yet, create one
      if (!data) {
        const { error: insertError } = await supabase
          .from('profiles')
          .insert([{ id: $user.id, onboarding_completed: false }]);
          
        if (insertError) throw insertError;
        onboardingCompleted = false;
      } else {
        onboardingCompleted = data.onboarding_completed ?? false;
      }
    } catch (error) {
      console.error('Error checking onboarding status:', error);
      // In case of error, assume onboarding is not completed
      onboardingCompleted = false;
    } finally {
      checkingOnboarding = false;
      initialCheckDone = true;
    }
  }

  const routes = {
    '/': Dashboard,
    '/signup': Signup,
    '/auth': Auth,
    '/settings': Settings,
    '/settings/artist-profile': ArtistProfileSettings,
    '/settings/organizer-profile': OrganizerProfileSettings,
    '/confirm-signup': ConfirmSignup,
    '/signup-confirmed': SignupConfirmed,
    '/dashboard': Dashboard,
    '/onboarding': Onboarding,
    '/explore': Explore,
    '/piece/:id': PieceDetail,
    '/view/:id': PieceViewer,
    '/update/:id': UpdatePiece,
    '/edit/:id': PieceEditorPage,
    '/notifications': Notifications,
    '/help': Help,
    '/terms': Terms,
    '/privacy': Privacy,
    '/payment-policy': PaymentPolicy,
    '/community': Community,
    '/forgot-password': ForgotPassword,
    '/reset-password(.*)': ResetPassword,
    '/profile/:username': Profile,
    '/artist/:username': ProfileArtist,
    '/organizer/:username': ProfileOrganizer,
    '/create-peace': CreatePiece,
    '/pieces': MyPieces,
    '/apply/:id': ApplyArtist,
    '/manage/:id': ManagePiece,
    '/review-application/:id': ReviewApplication,
  };

  // List of routes that require authentication
  const protectedRoutes = ['/', '/settings', '/settings/artist-profile', '/settings/organizer-profile', '/dashboard', '/onboarding', '/update/:id', '/edit/:id', '/notifications', '/create-peace', '/pieces', '/apply/:id', '/manage/:id', '/review-application/:id'];

  // List of routes that should only show top bar (no sidebar) regardless of auth status
  const topBarOnlyRoutes = ['/auth', '/signup', '/confirm-signup', '/signup-confirmed', '/onboarding', '/forgot-password', '/reset-password'];

  // List of routes that should have no UI chrome (fullscreen experience)
  const fullscreenRoutes = ['/view/:id', '/edit/:id'];

  // Helper function to get the clean path without hash fragments
  function getCleanPath(path: string): string {
    return path.split('#')[0];
  }

  // Helper function to check if a route is in a route list (handles hash fragments)
  function isRouteInList(path: string, routeList: string[]): boolean {
    const cleanPath = getCleanPath(path);
    return routeList.includes(cleanPath);
  }

  // Function to extract ID from path
  function extractIdFromPath(path: string, routePattern: string): string | null {
    const regex = new RegExp(routePattern.replace(':id', '([^/]+)'));
    const match = path.match(regex);
    return match ? match[1] : null;
  }

  // Check onboarding status when user changes
  $: if ($user && !initialCheckDone) {
    checkOnboardingStatus();
  }

  // Handle route protection and onboarding flow
  $: if ($location) {
    if (!$authLoading) {
      const currentPath = $location;
      const cleanPath = getCleanPath(currentPath);
      
      // Reset authorization states
      isAuthorizedToManage = false;
      pieceToManage = null;
      isAuthorizedToUpdate = false;
      pieceToUpdate = null;
      isAuthorizedToEdit = false;
      pieceToEdit = null;
      currentPathId = null;
      checkingManagementAuth = false;
      checkingUpdateAuth = false;
      checkingEditAuth = false;

      // Check for management route specifically
      if (cleanPath.startsWith('/manage/')) {
        currentPathId = extractIdFromPath(cleanPath, '/manage/:id');
        if (currentPathId) {
          checkingManagementAuth = true;
          if (!$user) {
            push('/auth'); // Redirect to auth if not logged in
          } else {
            // Fetch piece details to verify organizer
            supabase
              .from('piece_details')
              .select('id, title, organizer_user_id')
              .eq('id', currentPathId)
              .single()
              .then(({ data, error: pieceError }) => {
                if (pieceError || !data || data.organizer_user_id !== $user.id) {
                  console.warn('Unauthorized access attempt to manage piece:', currentPathId);
                  push('/dashboard'); // Redirect if not organizer or piece not found
                } else {
                  isAuthorizedToManage = true;
                  pieceToManage = data;
                }
              })
              .catch(err => {
                console.error('Error checking management authorization:', err);
                push('/dashboard'); // Redirect on error
              })
              .finally(() => checkingManagementAuth = false);
          }
        }
      } 
      // Check for update route specifically
      else if (cleanPath.startsWith('/update/')) {
        currentPathId = extractIdFromPath(cleanPath, '/update/:id');
        if (currentPathId) {
          checkingUpdateAuth = true;
          if (!$user) {
            push('/auth'); // Redirect to auth if not logged in
          } else {
            // Fetch piece details to verify organizer
            supabase
              .from('piece_details')
              .select('id, title, organizer_user_id')
              .eq('id', currentPathId)
              .single()
              .then(({ data, error: pieceError }) => {
                if (pieceError || !data || data.organizer_user_id !== $user.id) {
                  console.warn('Unauthorized access attempt to update piece:', currentPathId);
                  push('/dashboard'); // Redirect if not organizer or piece not found
                } else {
                  isAuthorizedToUpdate = true;
                  pieceToUpdate = data;
                }
              })
              .catch(err => {
                console.error('Error checking update authorization:', err);
                push('/dashboard'); // Redirect on error
              })
              .finally(() => checkingUpdateAuth = false);
          }
        }
      }
      // Check for edit route specifically
      else if (cleanPath.startsWith('/edit/')) {
        currentPathId = extractIdFromPath(cleanPath, '/edit/:id');
        if (currentPathId) {
          checkingEditAuth = true;
          if (!$user) {
            push('/auth'); // Redirect to auth if not logged in
          } else {
            // First, fetch piece details to check if user is the organizer
            supabase
              .from('piece_details')
              .select('id, title, organizer_user_id, contributors')
              .eq('id', currentPathId)
              .single()
              .then(async ({ data, error: pieceError }) => {
                if (pieceError || !data) {
                  console.warn('Error fetching piece or piece not found:', currentPathId);
                  push('/dashboard');
                  return;
                }
                
                // Check if user is the organizer
                if (data.organizer_user_id === $user.id) {
                  isAuthorizedToEdit = true;
                  pieceToEdit = data;
                  return;
                }
                
                // If not organizer, check if user is a contributor
                try {
                  // Get the user's artist ID
                  const { data: artistData, error: artistError } = await supabase
                    .from('artists')
                    .select('id')
                    .eq('user_id', $user.id)
                    .maybeSingle();
                    
                  if (artistError) throw artistError;
                  
                  if (artistData) {
                    userArtistId = artistData.id;
                    
                    // Check if the user's artist ID is in the contributors array
                    const contributors = data.contributors || [];
                    const isContributor = contributors.some((contributor: any) => contributor.id === userArtistId);
                    
                    if (isContributor) {
                      isAuthorizedToEdit = true;
                      pieceToEdit = data;
                      return;
                    }
                  }
                  
                  // If we get here, user is neither organizer nor contributor
                  console.warn('Unauthorized access attempt to edit piece:', currentPathId);
                  push('/dashboard');
                } catch (err) {
                  console.error('Error checking contributor status:', err);
                  push('/dashboard');
                }
              })
              .catch(err => {
                console.error('Error checking edit authorization:', err);
                push('/dashboard');
              })
              .finally(() => checkingEditAuth = false);
          }
        }
      }
      else if (!$user && protectedRoutes.includes(cleanPath)) {
        push('/auth');
      } else if ($user && !checkingOnboarding && initialCheckDone) {
        if (cleanPath === '/auth') {
          // After login, check onboarding status
          if (!onboardingCompleted) {
            push('/onboarding');
          } else {
            push('/dashboard');
          }
        }
      }
    }
  }

  // Determine if we should show the sidebar
  $: showSidebar = $user && !isRouteInList($location, topBarOnlyRoutes) && !fullscreenRoutes.some(route => {
    const routePattern = route.replace(':id', '[^/]+');
    return new RegExp(`^${routePattern}$`).test(getCleanPath($location));
  });

  // Determine if we should show the top bar
  $: showTopBar = !fullscreenRoutes.some(route => {
    const routePattern = route.replace(':id', '[^/]+');
    return new RegExp(`^${routePattern}$`).test(getCleanPath($location));
  });

  // Determine if we should show the footer
  $: showFooter = !fullscreenRoutes.some(route => {
    const routePattern = route.replace(':id', '[^/]+');
    return new RegExp(`^${routePattern}$`).test(getCleanPath($location));
  });

  // Determine if Auth component should be shown
  $: shouldShowAuthComponent = !$user && 
                               getCleanPath($location) !== '/auth' && 
                               !isRouteInList($location, topBarOnlyRoutes) && 
                               getCleanPath($location) !== '/explore' && 
                               !getCleanPath($location).startsWith('/piece/') && 
                               !getCleanPath($location).startsWith('/view/') && 
                               !getCleanPath($location).startsWith('/help') && 
                               !getCleanPath($location).startsWith('/terms') && 
                               !getCleanPath($location).startsWith('/privacy') && 
                               !getCleanPath($location).startsWith('/payment-policy') && 
                               !getCleanPath($location).startsWith('/community') && 
                               !getCleanPath($location).startsWith('/profile/');

  $: if ($location) {
    window.scrollTo(0, 0);
  }
</script>

<main>
  <div class="app-container">
    {#if showSidebar}
      <Sidebar 
        collapsed={sidebarCollapsed} 
        bind:isOpenOnMobile={mobileSidebarOpen}
        on:toggle={toggleSidebar} 
        on:toggleDarkMode={toggleDarkMode} 
      />
    {/if}
    
    <!-- Mobile Sidebar Overlay -->
    {#if isMobile && mobileSidebarOpen && showSidebar}
      <div class="mobile-sidebar-overlay" on:click={closeMobileSidebar}></div>
    {/if}
    
    <div class="main-content" class:with-sidebar={showSidebar && !isMobile} class:sidebar-collapsed={sidebarCollapsed && !isMobile}>
      {#if showTopBar && (!showSidebar || isMobile)}
        <div class="top-bar">
          <div class="top-bar-content">
            <div class="top-bar-left">
              {#if isMobile && showSidebar}
                <button class="mobile-menu-button" on:click={toggleMobileSidebar} aria-label="Open menu">
                  <svg viewBox="0 0 24 24" width="24" height="24" stroke="currentColor" stroke-width="2" fill="none">
                    <line x1="3" y1="6" x2="21" y2="6"></line>
                    <line x1="3" y1="12" x2="21" y2="12"></line>
                    <line x1="3" y1="18" x2="21" y2="18"></line>
                  </svg>
                </button>
              {/if}
              
              <a class="logo-link" href="/#/auth" target="_self">
                <div class="logo-icon">
                  <svg xmlns="http://www.w3.org/2000/svg" width="42" height="66" viewBox="0 0 42 66" fill="none">
                    <path d="M25.3202 0C28.0469 5.45346e-08 30.2573 2.21041 30.2573 4.93709V11.9901C30.2573 12.5354 29.8152 12.9775 29.2699 12.9775H22.1008L25.644 21.1168C26.2778 20.8125 26.9526 20.5609 27.666 20.3697C35.4895 18.2735 42.9379 24.7869 41.9035 32.82L38.672 57.9158C38.5593 58.7909 37.4427 59.09 36.9075 58.3885L26.6131 44.8935L22.641 52.5808L28.9396 64.3328L28.9555 64.3637C29.2771 65.0153 28.8039 65.7867 28.0692 65.7867H13.986C13.2397 65.7866 12.7632 64.9906 13.1157 64.3328L19.4142 52.5808L15.4197 44.8503L5.0925 58.3885C4.55733 59.09 3.44074 58.7909 3.32802 57.9158L0.0965279 32.82C-0.937889 24.7868 6.51049 18.2734 14.334 20.3697C15.0436 20.5599 15.715 20.8098 16.3457 21.1119L19.8869 12.9775H16.4335C13.7068 12.9775 11.4964 10.7671 11.4964 8.0404V0.987417C11.4964 0.442088 11.9385 1.22146e-05 12.4838 0H25.3202Z" fill="url(#paint0_linear_264_1443)"/>
                    <defs>
                      <linearGradient id="paint0_linear_264_1443" x1="21" y1="0" x2="21" y2="65.7867" gradientUnits="userSpaceOnUse">
                        <stop stop-color="var(--logo-gradient-stop1)"/>
                        <stop offset="1" stop-color="var(--logo-gradient-stop2)"/>
                      </linearGradient>
                    </defs>
                  </svg>
                </div>
                <span class="logo-text">Peace Piece</span>
              </a>
            </div>
            
            <ThemeToggle {darkMode} on:toggle={toggleDarkMode} />
          </div>
        </div>
      {/if}
      
      <div class="content-area">
        {#if $authLoading || checkingManagementAuth || checkingUpdateAuth || checkingEditAuth}
          <div class="loading">Loading...</div>
        {:else if shouldShowAuthComponent}
          <Auth />
        {:else if checkingOnboarding}
          <div class="loading">Loading...</div>
        {:else if getCleanPath($location).startsWith('/manage/') && !isAuthorizedToManage}
          <div class="error-container">
            <div class="error-card">
              <h2>Access Denied</h2>
              <p>You don't have permission to manage this piece.</p>
              <a href="/dashboard" use:link class="primary">Back to Dashboard</a>
            </div>
          </div>
        {:else if getCleanPath($location).startsWith('/manage/') && isAuthorizedToManage}
          <ManagePiece params={{ id: currentPathId }} />
        {:else if getCleanPath($location).startsWith('/update/') && !isAuthorizedToUpdate}
          <div class="error-container">
            <div class="error-card">
              <h2>Access Denied</h2>
              <p>You don't have permission to update this piece.</p>
              <a href="/dashboard" use:link class="primary">Back to Dashboard</a>
            </div>
          </div>
        {:else if getCleanPath($location).startsWith('/update/') && isAuthorizedToUpdate}
          <UpdatePiece params={{ id: currentPathId }} />
        {:else if getCleanPath($location).startsWith('/edit/') && !isAuthorizedToEdit}
          <div class="error-container">
            <div class="error-card">
              <h2>Access Denied</h2>
              <p>You don't have permission to edit this piece. Only organizers and contributors can access the editor.</p>
              <a href="/dashboard" use:link class="primary">Back to Dashboard</a>
            </div>
          </div>
        {:else if getCleanPath($location).startsWith('/edit/') && isAuthorizedToEdit}
          <PieceEditorPage params={{ id: currentPathId }} />
        {:else}
          <Router {routes} />
        {/if}
      </div>
      
      {#if showFooter}
        <Footer />
      {/if}
    </div>
  </div>
  <BoltBadge />
</main>

<style>
  .app-container {
    min-height: 100vh;
    display: flex;
    background: var(--bg-color);
  }
  
  .main-content {
    flex: 1;
    display: flex;
    flex-direction: column;
    transition: margin-left 0.3s ease;
    min-height: 100vh;
    position: relative;
  }

  .main-content.with-sidebar {
    margin-left: 280px;
  }

  .main-content.with-sidebar.sidebar-collapsed {
    margin-left: 69px;
  }

  .mobile-sidebar-overlay {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background-color: rgba(0, 0, 0, 0.5);
    z-index: 150;
    backdrop-filter: blur(2px);
  }

  .top-bar {
    background: var(--bg-color);
    border-bottom: 1px solid var(--border-color);
    padding: var(--space-4);
    position: sticky;
    top: 0;
    z-index: 10;
  }

  .top-bar-content {
    display: flex;
    align-items: center;
    justify-content: space-between;
    max-width: 1400px;
    margin: 0 auto;
  }

  .top-bar-left {
    display: flex;
    align-items: center;
    gap: var(--space-3);
  }

  .mobile-menu-button {
    background: none;
    border: none;
    color: var(--text-color);
    cursor: pointer;
    padding: var(--space-2);
    border-radius: var(--radius-md);
    display: flex;
    align-items: center;
    justify-content: center;
    transition: background 0.2s;
  }

  .mobile-menu-button:hover {
    background: var(--border-color);
  }

  .logo,
  .logo-link {
    display: flex;
    align-items: center;
    gap: var(--space-3);
  }

  .logo-icon {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 32px;
    height: 32px;
  }

  .logo-icon svg {
    width: 100%;
    height: 100%;
  }

  .logo-text {
    font-weight: 500;
    font-size: 1.5rem;
    color: var(--text-color);
    font-family: var(--font-instrument-sans);
  }

  .content-area {
    flex: 1;
    overflow-y: auto;
  }
  
  .loading {
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 200px;
    color: var(--text-muted);
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
  }

  .error-container {
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 400px;
    padding: var(--space-6);
  }

  .error-card {
    background: var(--card-bg);
    border: 1px solid var(--color-error-200);
    border-radius: var(--radius-lg);
    padding: var(--space-8);
    text-align: center;
    max-width: 500px;
  }

  .error-card h2 {
    color: var(--color-error-600);
    margin-bottom: var(--space-4);
  }

  /* Mobile responsiveness */
  @media (max-width: 768px) {
    .main-content.with-sidebar {
      margin-left: 0;
    }

    .main-content.with-sidebar.sidebar-collapsed {
      margin-left: 0;
    }
  }
</style>