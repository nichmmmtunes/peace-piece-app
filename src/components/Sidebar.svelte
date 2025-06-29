<script lang="ts">
  import { createEventDispatcher } from 'svelte';
  import { link, location } from 'svelte-spa-router';
  import { user, signOut } from '../stores/authStore';
  import { supabase } from '../lib/supabase';
  import { onMount, onDestroy } from 'svelte';
  import ThemeToggle from './ThemeToggle.svelte';
  
  export let collapsed = false;
  export let isOpenOnMobile = false;
  
  const dispatch = createEventDispatcher();
  
  let unreadNotifications = 0;
  let subscription: any = null;
  let collapseButton: HTMLButtonElement;
  let userProfile: any = null;
  let showProfileMenu = false;
  let profileMenuElement: HTMLElement;
  let darkMode = false;
  
  async function handleSignOut() {
    await signOut();
  }

  function toggleSidebar() {
    dispatch('toggle');
    // Unfocus the collapse button after toggling
    if (collapseButton) {
      collapseButton.blur();
    }
  }

  function toggleProfileMenu() {
    showProfileMenu = !showProfileMenu;
  }

  function closeProfileMenu() {
    showProfileMenu = false;
  }

  function toggleDarkMode() {
    darkMode = !darkMode;
    dispatch('toggleDarkMode');
  }

  function navigateToProfile() {
    if (userProfile?.username) {
      closeProfileMenu();
      // Use the link action to navigate
      window.location.hash = `/profile/${userProfile.username}`;
    }
  }

  // NEW: Function to handle navigation clicks and close mobile sidebar
  function handleNavigationClick() {
    // Close mobile sidebar when navigation item is clicked
    isOpenOnMobile = false;
  }

  // Close menu when clicking outside
  function handleClickOutside(event: MouseEvent) {
    if (showProfileMenu && profileMenuElement && !profileMenuElement.contains(event.target as Node)) {
      closeProfileMenu();
    }
  }

  async function loadUnreadCount() {
    if (!$user) return;

    try {
      const { count, error } = await supabase
        .from('notifications')
        .select('*', { count: 'exact', head: true })
        .eq('user_id', $user.id)
        .eq('read', false);

      if (error) throw error;

      unreadNotifications = count || 0;
    } catch (error) {
      console.error('Error loading unread notifications count:', error);
    }
  }

  async function loadUserProfile() {
    if (!$user) return;

    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('username, avatar_url')
        .eq('id', $user.id)
        .maybeSingle();

      if (error) throw error;

      userProfile = data;
    } catch (error) {
      console.error('Error loading user profile:', error);
    }
  }

  onMount(() => {
    // Check system theme preference
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    darkMode = prefersDark;

    // Add click outside listener
    document.addEventListener('click', handleClickOutside);

    if ($user) {
      loadUnreadCount();
      loadUserProfile();

      subscription = supabase
        .channel('notification-count-sidebar')
        .on('postgres_changes', 
          { 
            event: '*', 
            schema: 'public', 
            table: 'notifications',
            filter: `user_id=eq.${$user.id}`
          }, 
          () => {
            loadUnreadCount();
          }
        )
        .subscribe();
    }
  });

  onDestroy(() => {
    document.removeEventListener('click', handleClickOutside);
    if (subscription) {
      supabase.removeChannel(subscription);
    }
  });

  $: if ($user) {
    loadUnreadCount();
    loadUserProfile();
  } else {
    unreadNotifications = 0;
    userProfile = null;
  }

  const navigationItems = [
    { path: '/dashboard', label: 'Dashboard', icon: 'dashboard' },
    { path: '/pieces', label: 'My Pieces', icon: 'pieces' },
    { path: '/explore', label: 'Explore', icon: 'explore' },
    { path: '/notifications', label: 'Updates', icon: 'notifications', badge: unreadNotifications },
    { path: '/settings', label: 'Settings', icon: 'settings' },
  ];

  const profileMenuItems = [
    { path: '/help', label: 'Help & FAQ', icon: 'help' },
    { path: '/terms', label: 'Terms of Use', icon: 'document' },
    { path: '/privacy', label: 'Privacy Policy', icon: 'shield' },
    { path: '/community', label: 'Community Policies', icon: 'users' },
    { path: '/payment-policy', label: 'Payment Policy', icon: 'dollars' },
  ];

  function getIcon(iconName: string) {
    const icons = {
      dashboard: `<svg width="18" height="20" viewBox="0 0 18 20" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M1.5 18.7502H6.11531V12.4039C6.11531 12.1179 6.21208 11.8781 6.40563 11.6845C6.59917 11.4912 6.83896 11.3945 7.125 11.3945H10.875C11.161 11.3945 11.4008 11.4912 11.5944 11.6845C11.7879 11.8781 11.8847 12.1179 11.8847 12.4039V18.7502H16.5V7.88484C16.5 7.75651 16.472 7.64026 16.4159 7.53609C16.3599 7.43193 16.2838 7.33984 16.1875 7.25984L9.45687 2.18766C9.32854 2.07557 9.17625 2.01953 9 2.01953C8.82375 2.01953 8.67146 2.07557 8.54313 2.18766L1.8125 7.25984C1.71625 7.33984 1.6401 7.43193 1.58406 7.53609C1.52802 7.64026 1.5 7.75651 1.5 7.88484V18.7502ZM0.25 18.7502V7.88484C0.25 7.56505 0.321562 7.26214 0.464687 6.97609C0.607604 6.69005 0.805313 6.45453 1.05781 6.26953L7.78844 1.17328C8.14073 0.904114 8.54333 0.769531 8.99625 0.769531C9.44917 0.769531 9.85427 0.904114 10.2116 1.17328L16.9422 6.26953C17.1947 6.45453 17.3924 6.69005 17.5353 6.97609C17.6784 7.26214 17.75 7.56505 17.75 7.88484V18.7502C17.75 19.0852 17.6254 19.3772 17.3762 19.6264C17.1271 19.8756 16.835 20.0002 16.5 20.0002H11.6444C11.3581 20.0002 11.1183 19.9034 10.925 19.7098C10.7315 19.5163 10.6347 19.2765 10.6347 18.9905V12.6445H7.36531V18.9905C7.36531 19.2765 7.26854 19.5163 7.075 19.7098C6.88167 19.9034 6.64188 20.0002 6.35563 20.0002H1.5C1.165 20.0002 0.872917 19.8756 0.62375 19.6264C0.374584 19.3772 0.25 19.0852 0.25 18.7502Z" fill="currentColor"/>
      </svg>
      `,
      pieces: `<svg viewBox="0 0 24 24" width="20" height="20" stroke="currentColor" stroke-width="2" fill="none">
        <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"></path>
        <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"></path>
      </svg>`,
      explore: `<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M8.14188 16.4953L13.4688 14.7788C13.7892 14.6698 14.0604 14.5044 14.2825 14.2825C14.5044 14.0604 14.6698 13.7892 14.7787 13.4688L16.5 8.13656C16.5594 7.94302 16.5151 7.77375 16.3672 7.62875C16.2193 7.48354 16.0496 7.44219 15.8581 7.50469L10.5312 9.22125C10.2108 9.33021 9.93958 9.49563 9.7175 9.7175C9.49562 9.93958 9.33021 10.2108 9.22125 10.5312L7.5 15.8634C7.44063 16.057 7.4849 16.2263 7.63281 16.3713C7.78073 16.5165 7.95042 16.5578 8.14188 16.4953ZM11.9944 13.3944C11.6054 13.3944 11.2768 13.2582 11.0084 12.9859C10.7399 12.7136 10.6056 12.3831 10.6056 11.9944C10.6056 11.6054 10.7418 11.2768 11.0141 11.0084C11.2864 10.7399 11.6169 10.6056 12.0056 10.6056C12.3946 10.6056 12.7232 10.7418 12.9916 11.0141C13.2601 11.2864 13.3944 11.6169 13.3944 12.0056C13.3944 12.3946 13.2582 12.7232 12.9859 12.9916C12.7136 13.2601 12.3831 13.3944 11.9944 13.3944ZM12.0041 23.25C10.4484 23.25 8.98583 22.9548 7.61625 22.3644C6.24687 21.774 5.05562 20.9727 4.0425 19.9606C3.02938 18.9485 2.2274 17.7583 1.63656 16.39C1.04552 15.0219 0.75 13.5599 0.75 12.0041C0.75 10.4484 1.04521 8.98583 1.63562 7.61625C2.22604 6.24687 3.02729 5.05562 4.03938 4.0425C5.05146 3.02937 6.24167 2.2274 7.61 1.63656C8.97812 1.04552 10.4401 0.75 11.9959 0.75C13.5516 0.75 15.0142 1.04521 16.3838 1.63563C17.7531 2.22604 18.9444 3.02729 19.9575 4.03938C20.9706 5.05146 21.7726 6.24167 22.3634 7.61C22.9545 8.97813 23.25 10.4401 23.25 11.9959C23.25 13.5516 22.9548 15.0142 22.3644 16.3837C21.774 17.7531 20.9727 18.9444 19.9606 19.9575C18.9485 20.9706 17.7583 21.7726 16.39 22.3634C15.0219 22.9545 13.5599 23.25 12.0041 23.25ZM12 22C14.7869 22 17.1502 21.03 19.09 19.09C21.03 17.1502 22 14.7869 22 12C22 9.21313 21.03 6.84979 19.09 4.91C17.1502 2.97 14.7869 2 12 2C9.21313 2 6.84979 2.97 4.91 4.91C2.97 6.84979 2 9.21313 2 12C2 14.7869 2.97 17.1502 4.91 19.09C6.84979 21.03 9.21313 22 12 22Z" fill="currentColor"/>
      </svg>
      `,
      notifications: `<svg width="18" height="23" viewBox="0 0 18 23" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M6.69219 19.9328L1.72594 22.4881C1.38948 22.6644 1.05937 22.6567 0.735625 22.465C0.411875 22.2735 0.25 21.9864 0.25 21.6034V7.57688C0.25 7.01771 0.446667 6.54135 0.84 6.14781C1.23354 5.75448 1.71 5.55781 2.26937 5.55781H11.0912C11.6506 5.55781 12.127 5.75448 12.5203 6.14781C12.9139 6.54135 13.1106 7.01771 13.1106 7.57688V21.6034C13.1106 21.9864 12.9488 22.2735 12.625 22.465C12.3013 22.6567 11.9711 22.6644 11.6347 22.4881L6.69219 19.9328ZM1.5 21.2475L5.74531 19.0169C6.0401 18.8567 6.35177 18.7766 6.68031 18.7766C7.00885 18.7766 7.32052 18.8567 7.61531 19.0169L11.8606 21.2475V7.57688C11.8606 7.3525 11.7885 7.16823 11.6444 7.02406C11.5 6.8799 11.3156 6.80781 11.0912 6.80781H2.26937C2.045 6.80781 1.86062 6.8799 1.71625 7.02406C1.57208 7.16823 1.5 7.3525 1.5 7.57688V21.2475ZM17.125 18.8028C16.9471 18.8028 16.7984 18.7431 16.6791 18.6238C16.5597 18.5044 16.5 18.3557 16.5 18.1778V2.76937C16.5 2.545 16.4279 2.36062 16.2838 2.21625C16.1394 2.07208 15.955 2 15.7306 2H4.36063C4.18271 2 4.03406 1.94031 3.91469 1.82094C3.79531 1.70156 3.73563 1.55292 3.73563 1.375C3.73563 1.19708 3.79531 1.04844 3.91469 0.929062C4.03406 0.809687 4.18271 0.75 4.36063 0.75H15.7306C16.29 0.75 16.7665 0.946667 17.16 1.34C17.5533 1.73354 17.75 2.21 17.75 2.76937V18.1778C17.75 18.3557 17.6903 18.5044 17.5709 18.6238C17.4516 18.7431 17.3029 18.8028 17.125 18.8028Z" fill="currentColor"/>
      </svg>
      `,
      settings: `<svg width="22" height="24" viewBox="0 0 22 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M9.69857 23.25C9.40857 23.25 9.15659 23.1547 8.94263 22.9641C8.72867 22.7732 8.59607 22.5352 8.54482 22.25L8.21544 19.6347C7.81648 19.5145 7.38503 19.3253 6.92107 19.0672C6.45711 18.8093 6.06252 18.5329 5.73732 18.2381L3.34294 19.2669C3.07857 19.3837 2.81013 19.3966 2.53763 19.3053C2.26513 19.2139 2.05523 19.0407 1.90794 18.7859L0.559191 16.4641C0.411899 16.2093 0.36867 15.9432 0.429504 15.6659C0.490337 15.3886 0.635337 15.161 0.864504 14.9831L2.95357 13.4206C2.91669 13.1948 2.88627 12.9621 2.86232 12.7225C2.83815 12.4829 2.82607 12.2501 2.82607 12.0241C2.82607 11.8141 2.83815 11.5933 2.86232 11.3619C2.88627 11.1302 2.91669 10.8694 2.95357 10.5794L0.864504 9.01687C0.635337 8.83896 0.494295 8.6074 0.441378 8.32219C0.38867 8.03698 0.435962 7.76688 0.583254 7.51188L1.90794 5.26188C2.05523 5.02313 2.26513 4.85406 2.53763 4.75469C2.81013 4.65531 3.07857 4.66417 3.34294 4.78125L5.71325 5.78594C6.08659 5.47511 6.49044 5.19469 6.92482 4.94469C7.35898 4.69469 7.78117 4.50156 8.19138 4.36531L8.54482 1.75C8.59607 1.46479 8.72867 1.22677 8.94263 1.03594C9.15659 0.845313 9.40857 0.75 9.69857 0.75H12.2998C12.5898 0.75 12.8418 0.845313 13.0558 1.03594C13.2697 1.22677 13.4023 1.46479 13.4536 1.75L13.7829 4.38938C14.2621 4.55771 14.6855 4.75083 15.0533 4.96875C15.421 5.18667 15.7996 5.45906 16.1892 5.78594L18.6795 4.78125C18.9439 4.66417 19.2123 4.65531 19.4848 4.75469C19.7573 4.85406 19.9672 5.02313 20.1145 5.26188L21.4392 7.53594C21.5865 7.79073 21.6297 8.05677 21.5689 8.33406C21.508 8.61135 21.363 8.83896 21.1339 9.01687L18.9486 10.6516C19.0175 10.9095 19.0561 11.1462 19.0642 11.3619C19.0721 11.5773 19.0761 11.79 19.0761 12C19.0761 12.194 19.068 12.3986 19.052 12.6141C19.036 12.8297 18.9991 13.0905 18.9414 13.3966L21.0545 14.9831C21.2837 15.161 21.4327 15.3886 21.5017 15.6659C21.5704 15.9432 21.5312 16.2093 21.3839 16.4641L20.052 18.7619C19.9047 19.0169 19.6908 19.19 19.4101 19.2812C19.1297 19.3725 18.8573 19.3597 18.5929 19.2428L16.1892 18.2141C15.7996 18.5409 15.4077 18.8214 15.0136 19.0553C14.6194 19.2893 14.2092 19.4744 13.7829 19.6106L13.4536 22.25C13.4023 22.5352 13.2697 22.7732 13.0558 22.9641C12.8418 23.1547 12.5898 23.25 12.2998 23.25H9.69857ZM9.74919 22H12.1939L12.6554 18.6153C13.2852 18.4486 13.8521 18.2199 14.3561 17.9291C14.8602 17.6382 15.3735 17.2396 15.8958 16.7331L19.0136 18.0625L20.2564 15.9375L17.5208 13.8822C17.6249 13.5264 17.6939 13.1991 17.7276 12.9003C17.7612 12.6014 17.7779 12.3013 17.7779 12C17.7779 11.6827 17.7612 11.3826 17.7276 11.0997C17.6939 10.817 17.6249 10.5057 17.5208 10.1659L20.3045 8.0625L19.0617 5.9375L15.8717 7.27406C15.4936 6.85906 14.9964 6.47 14.3801 6.10687C13.7641 5.74396 13.1812 5.50323 12.6314 5.38469L12.2492 2H9.75638L9.367 5.36062C8.73721 5.49521 8.15825 5.71198 7.63013 6.01094C7.10221 6.30969 6.577 6.72031 6.0545 7.24281L2.93669 5.9375L1.69388 8.0625L4.40544 10.0866C4.30128 10.367 4.22836 10.6715 4.18669 11C4.14502 11.3285 4.12419 11.6699 4.12419 12.0241C4.12419 12.3414 4.14502 12.6563 4.18669 12.9688C4.22836 13.2813 4.29325 13.5857 4.38138 13.8822L1.69388 15.9375L2.93669 18.0625L6.03044 16.75C6.52086 17.2452 7.03003 17.6423 7.55794 17.9412C8.08607 18.24 8.68107 18.4727 9.34294 18.6394L9.74919 22ZM10.9654 15.125C11.8373 15.125 12.5762 14.8221 13.182 14.2163C13.7876 13.6106 14.0904 12.8719 14.0904 12C14.0904 11.1281 13.7876 10.3894 13.182 9.78375C12.5762 9.17792 11.8373 8.875 10.9654 8.875C10.089 8.875 9.34898 9.17792 8.74544 9.78375C8.14211 10.3894 7.84044 11.1281 7.84044 12C7.84044 12.8719 8.14211 13.6106 8.74544 14.2163C9.34898 14.8221 10.089 15.125 10.9654 15.125Z" fill="currentColor"/>
      </svg>
      `,
      help: `<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M9.99955 19.9995C9.82226 19.9995 9.67393 19.9396 9.55455 19.8198C9.43518 19.7 9.37549 19.5516 9.37549 19.3745V10.6245H0.625488C0.448405 10.6245 0.299967 10.5645 0.180176 10.4445C0.0603841 10.3245 0.000488281 10.1759 0.000488281 9.99857C0.000488281 9.82128 0.0603841 9.67295 0.180176 9.55357C0.299967 9.4342 0.448405 9.37451 0.625488 9.37451H9.37549V0.624512C9.37549 0.447428 9.43549 0.298991 9.55549 0.179199C9.67549 0.0594075 9.82413 -0.000488281 10.0014 -0.000488281C10.1787 -0.000488281 10.327 0.0594075 10.4464 0.179199C10.5658 0.298991 10.6255 0.447428 10.6255 0.624512V9.37451H19.3755C19.5526 9.37451 19.701 9.43451 19.8208 9.55451C19.9406 9.67451 20.0005 9.82316 20.0005 10.0004C20.0005 10.1777 19.9406 10.3261 19.8208 10.4454C19.701 10.5648 19.5526 10.6245 19.3755 10.6245H10.6255V19.3745C10.6255 19.5516 10.5655 19.7 10.4455 19.8198C10.3255 19.9396 10.1768 19.9995 9.99955 19.9995Z" fill="currentColor"/>
      </svg>
      `,
      document: `<svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
        <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
        <polyline points="14 2 14 8 20 8"></polyline>
        <line x1="16" y1="13" x2="8" y2="13"></line>
        <line x1="16" y1="17" x2="8" y2="17"></line>
        <polyline points="10 9 9 9 8 9"></polyline>
      </svg>`,
      shield: `<svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
        <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path>
      </svg>`,
      dollars: `<svg width="13" height="19" viewBox="0 0 13 19" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M11.6729 9.5C11.0043 8.9208 10.1542 8.61336 9.28187 8.63524H3.67478C3.41913 8.64191 3.16481 8.59521 2.92703 8.49793C2.68926 8.40065 2.47292 8.2548 2.29098 8.0691C2.10904 7.8834 1.96523 7.66168 1.86816 7.4172C1.77109 7.17273 1.72275 6.91052 1.72605 6.64629C1.71982 6.54345 1.71982 6.4403 1.72605 6.33745C1.80144 5.8653 2.04103 5.43782 2.39985 5.13529C2.75867 4.83276 3.21202 4.67599 3.67478 4.69441H9.19818C9.64873 4.694 10.0848 4.85897 10.4286 5.1599C10.7723 5.46083 11.0015 5.87815 11.0752 6.33745H12.8685C12.7934 5.3849 12.3742 4.49642 11.6942 3.84866C11.0141 3.2009 10.1231 2.8413 9.19818 2.84135H7.30923V0H5.8148V2.84135H3.67478C2.74989 2.8413 1.85885 3.2009 1.17881 3.84866C0.498775 4.49642 0.0795453 5.3849 0.00447298 6.33745C-0.00149099 6.44031 -0.00149099 6.54344 0.00447298 6.64629C0.00447298 7.14434 0.0994083 7.63752 0.283859 8.09765C0.468309 8.55779 0.738662 8.97588 1.07948 9.32806C1.7678 10.0393 2.70136 10.4389 3.67478 10.4389H9.34164C9.59527 10.4323 9.84761 10.4782 10.0838 10.574C10.32 10.6697 10.5352 10.8134 10.7168 10.9964C10.8984 11.1795 11.0427 11.3983 11.1412 11.6398C11.2397 11.8814 11.2905 12.141 11.2904 12.4031C11.3028 12.5428 11.3028 12.6834 11.2904 12.8231C11.1955 13.2578 10.9603 13.6462 10.6236 13.9246C10.2868 14.2029 9.86852 14.3547 9.43729 14.355H3.81825C3.38702 14.3547 2.96869 14.2029 2.63195 13.9246C2.29522 13.6462 2.06008 13.2578 1.96516 12.8231H0.159893C0.262636 13.7513 0.69227 14.608 1.36693 15.23C2.04159 15.852 2.91412 16.1957 3.81825 16.1957H5.8148V19H7.30923V16.1957H9.34164C10.2458 16.1957 11.1183 15.852 11.793 15.23C12.4676 14.608 12.8973 13.7513 13 12.8231V12.4031C12.9986 11.8482 12.8789 11.3005 12.6496 10.7987C12.4202 10.297 12.0868 9.8536 11.6729 9.5Z" fill="currentColor"/>
</svg>
      `,
      users: `<svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
        <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
        <circle cx="9" cy="7" r="4"></circle>
        <path d="M23 21v-2a4 4 0 0 0-3-3.87"></path>
        <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
      </svg>`,
      add: `<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M9.99955 19.9995C9.82226 19.9995 9.67393 19.9396 9.55455 19.8198C9.43518 19.7 9.37549 19.5516 9.37549 19.3745V10.6245H0.625488C0.448405 10.6245 0.299967 10.5645 0.180176 10.4445C0.0603841 10.3245 0.000488281 10.1759 0.000488281 9.99857C0.000488281 9.82128 0.0603841 9.67295 0.180176 9.55357C0.299967 9.4342 0.448405 9.37451 0.625488 9.37451H9.37549V0.624512C9.37549 0.447428 9.43549 0.298991 9.55549 0.179199C9.67549 0.0594075 9.82413 -0.000488281 10.0014 -0.000488281C10.1787 -0.000488281 10.327 0.0594075 10.4464 0.179199C10.5658 0.298991 10.6255 0.447428 10.6255 0.624512V9.37451H19.3755C19.5526 9.37451 19.701 9.43451 19.8208 9.55451C19.9406 9.67451 20.0005 9.82316 20.0005 10.0004C20.0005 10.1777 19.9406 10.3261 19.8208 10.4454C19.701 10.5648 19.5526 10.6245 19.3755 10.6245H10.6255V19.3745C10.6255 19.5516 10.5655 19.7 10.4455 19.8198C10.3255 19.9396 10.1768 19.9995 9.99955 19.9995Z" fill="currentColor"/>
      </svg>
    `
    };
    return icons[iconName] || '';
  }
</script>

<aside class="sidebar" class:collapsed class:mobile-open={isOpenOnMobile}>
  <div class="sidebar-header">
    <div class="logo">
      <a href="https://www.peacepiece.art/" class="logo-link">
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
        {#if !collapsed}
          <span class="logo-text">Peace Piece</span>
        {/if}
      </a>
    </div>
    
    <button 
      bind:this={collapseButton}
      class="collapse-btn" 
      on:click={toggleSidebar}
      aria-label={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
    >
      <svg viewBox="0 0 24 24" width="20" height="20" stroke="currentColor" stroke-width="2" fill="none">
        {#if collapsed}
          <path d="M9 18l6-6-6-6"></path>
        {:else}
          <path d="M15 18l-6-6 6-6"></path>
        {/if}
      </svg>
    </button>
  </div>

  <nav class="sidebar-nav">
    {#each navigationItems as item}
      <a 
        href={item.path} 
        use:link 
        class="nav-item"
        class:active={$location === item.path}
        title={collapsed ? item.label : ''}
        on:click={handleNavigationClick}
      >
        <div class="nav-icon">
          {@html getIcon(item.icon)}
        </div>
        {#if !collapsed}
          <span class="nav-label">{item.label}</span>
          {#if item.badge && item.badge > 0}
            <span class="nav-badge">{item.badge}</span>
          {/if}
        {:else if item.badge && item.badge > 0}
          <span class="nav-badge-collapsed">{item.badge}</span>
        {/if}
      </a>
    {/each}
  </nav>

  <!-- New Peace Piece Button -->
  <div class="create-piece-container">
    <a 
      href="/create-peace" 
      use:link 
      class="create-piece-btn"
      title={collapsed ? "Create New Peace Piece" : ""}
      on:click={handleNavigationClick}
    >
      <div class="create-icon">
        {@html getIcon('add')}
      </div>
      {#if !collapsed}
        <span class="create-label">New Peace Piece</span>
      {/if}
    </a>
  </div>

  <div class="sidebar-footer">
    {#if $user}
      <!-- Profile Row -->
      <div class="profile-row">
        <button class="profile-info" on:click={navigateToProfile}>
          <div class="profile-avatar">
            {#if userProfile?.avatar_url}
              <img src={userProfile.avatar_url} alt="Profile" class="avatar-image" />
            {:else}
              <div class="avatar-placeholder">
                {userProfile?.username?.[0]?.toUpperCase() || $user.email?.[0]?.toUpperCase() || '?'}
              </div>
            {/if}
          </div>
          {#if !collapsed}
            <div class="profile-details">
              <span class="username">{userProfile?.username || 'User'}</span>
            </div>
          {/if}
        </button>
        
        {#if !collapsed}
          <div class="profile-menu-container" bind:this={profileMenuElement}>
            <button 
              class="profile-menu-btn" 
              on:click={toggleProfileMenu}
              title="Profile menu"
            >
              <svg viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none">
                <circle cx="12" cy="12" r="1"></circle>
                <circle cx="12" cy="5" r="1"></circle>
                <circle cx="12" cy="19" r="1"></circle>
              </svg>
            </button>

            {#if showProfileMenu}
              <div class="profile-menu">
                <!-- Theme Toggle -->
                <div class="menu-item theme-toggle-item">
                  <div class="menu-item-content">
                    <span>{darkMode ? 'Light Mode' : 'Dark Mode'}</span>
                  </div>
                  <ThemeToggle {darkMode} on:toggle={toggleDarkMode} />
                </div>

                <!-- Separator -->
                <div class="menu-separator"></div>

                <!-- Menu Items -->
                {#each profileMenuItems as item}
                  <a 
                    href={item.path} 
                    use:link 
                    class="menu-item"
                    on:click={() => {
                      closeProfileMenu();
                      handleNavigationClick();
                    }}
                  >
                    <div class="menu-item-content">
                      {@html getIcon(item.icon)}
                      <span>{item.label}</span>
                    </div>
                  </a>
                {/each}

                <!-- Separator -->
                <div class="menu-separator"></div>

                <!-- Sign Out Row -->
                <div class="signout-row">
                  <button 
                    class="sign-out-btn" 
                    on:click={handleSignOut}
                    title={collapsed ? 'Sign Out' : ''}
                  >
                    <svg viewBox="0 0 24 24" width="20" height="20" stroke="currentColor" stroke-width="2" fill="none">
                      <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path>
                      <polyline points="16 17 21 12 16 7"></polyline>
                      <line x1="21" y1="12" x2="9" y2="12"></line>
                    </svg>
                    {#if !collapsed}
                      <span>Sign Out</span>
                    {/if}
                  </button>
                </div>
              </div>
            {/if}
          </div>
        {/if}
      </div>

    {/if}
  </div>
</aside>

<style>
  .sidebar {
    position: fixed;
    left: 0;
    top: 0;
    height: 100vh;
    width: 280px;
    background: var(--card-bg);
    border-right: none;
    display: flex;
    flex-direction: column;
    transition: width 0.3s ease;
    z-index: 100;
    overflow: hidden;
  }

  :global(.light-mode) .sidebar {
    border-right: solid 1px var(--border-color);
  }

  .sidebar.collapsed {
    width: 69px;
  }

  .sidebar-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: var(--space-4);
    border-bottom: 1px solid var(--border-color);
    min-height: 80px;
  }

  .logo {
    display: flex;
    align-items: center;
    gap: var(--space-3);
  }

  .logo-link {
    display: flex;
    align-items: center;
    gap: var(--space-3);
    text-decoration: none;
    color: inherit;
  }

  .logo-icon {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 32px;
    height: 32px;
    flex-shrink: 0;
    transition: all .3s ease;
    opacity: 1;
    margin-right: 0;
    position: relative;
    left: 2.2px;
  }

  .sidebar:not(.collapsed) .logo .logo-icon {
    opacity: 0;
    margin-right: -37px;
  }

  .logo-icon svg {
    width: 100%;
    height: 100%;
  }

  .logo-text {
    font-weight: 500;
    font-size: 1.5rem;
    color: var(--text-color);
    white-space: nowrap;
    position: relative;
    top: 3px;
    font-family: var(--font-instrument-sans);
  }

  .collapse-btn {
    background: none;
    border: none;
    color: var(--text-muted);
    cursor: pointer;
    padding: var(--space-2);
    border-radius: var(--radius-md);
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all 0.2s;
    flex-shrink: 0;
    position: relative;
    top: 4px;
  }

  .sidebar.collapsed .collapse-btn {
    padding: 0px;
    border-radius: 4px 0px 0px 4px;
  }

  .collapse-btn:hover {
    background: var(--border-color);
    color: var(--text-color);
  }

  .sidebar-nav {
    flex: 1;
    padding: var(--space-4) 0;
    overflow-y: auto;
    display: flex;
    flex-direction: column;
    gap: 10px;
  }

  .sidebar:not(.collapsed) .sidebar-nav {
    margin: 0 0 0 6px;
  }

  .nav-item {
    display: flex;
    align-items: center;
    gap: var(--space-3);
    padding: 0px;
    color: var(--text-color);
    text-decoration: none;
    transition: all 0.2s;
    position: relative;
    margin: 0 var(--space-2);
  }

  .nav-item:hover {
    color: var(--text-color);
  }

  .sidebar.collapsed .nav-item {
    justify-content: center;
  }

  .nav-icon {
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
    border-radius: 100px;
    background: var(--bg-color);
    padding: 10px;
    filter: drop-shadow(2px 4px 6px rgba(0,0,0,.1));
    width: 40px;
    height: 40px;
  }

  .nav-item.active .nav-icon {
    background: var(--text-color);
    color: var(--bg-color);
  }

  .nav-label {
    font-weight: 500;
    white-space: nowrap;
  }

  .nav-badge {
    background-color: var(--color-error-600);
    color: white;
    font-size: 0.75rem;
    font-weight: 500;
    padding: 2px 6px;
    border-radius: 10px;
    min-width: 18px;
    height: 18px;
    display: flex;
    align-items: center;
    justify-content: center;
    margin-left: auto;
  }

  .nav-badge-collapsed {
    position: absolute;
    top: 8px;
    right: 8px;
    background-color: var(--color-error-600);
    color: white;
    font-size: 0.75rem;
    font-weight: 500;
    padding: 2px 6px;
    border-radius: 10px;
    min-width: 18px;
    height: 18px;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  /* New Peace Piece Button */
  .create-piece-container {
    padding: var(--space-4);
  }

  .create-piece-btn {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: var(--space-3);
    background: var(--bg-color);
    color: var(--text-color);
    padding: var(--space-3);
    border-radius: 100px;
    text-decoration: none;
    font-weight: 500;
    transition: all 0.2s;
    width: 100%;
  }

  .create-piece-btn:hover {
    background-color: var(--color-primary-600);
    color: white;
    transform: translateY(-1px);
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  }

  .create-icon {
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
  }

  .create-label {
    white-space: nowrap;
  }

  .sidebar-footer {
    border-top: 1px solid var(--border-color);
    padding: var(--space-4);
    display: flex;
    flex-direction: column;
    gap: var(--space-3);
  }

  .profile-row {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: var(--space-3);
  }

  .profile-info {
    display: flex;
    align-items: center;
    gap: var(--space-3);
    flex: 1;
    min-width: 0;
    background: none;
    border: none;
    padding: 0;
    cursor: pointer;
    text-align: left;
    transition: opacity 0.2s;
    border-radius: 17px;
  }

  .profile-info:hover {
    opacity: 0.8;
  }

  .profile-avatar {
    width: 35px;
    height: 45px;
    overflow: hidden;
    border-radius: 100px;
    border: solid 2px var(--bg-color);
    filter: drop-shadow(2px 4px 6px rgba(0,0,0,.1));
  }

  .avatar-image {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  .avatar-placeholder {
    width: 100%;
    height: 100%;
    background-color: var(--color-neutral-200);
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: 500;
    color: var(--color-neutral-600);
    font-size: 0.875rem;
  }

  .profile-details {
    flex: 1;
    min-width: 0;
  }

  .username {
    font-size: 0.875rem;
    font-weight: 500;
    color: var(--text-color);
    display: block;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .profile-menu-container {
    position: relative;
  }

  .profile-menu-btn {
    background: none;
    border: none;
    color: var(--text-muted);
    cursor: pointer;
    padding: var(--space-1);
    border-radius: var(--radius-md);
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all 0.2s;
    flex-shrink: 0;
  }

  .profile-menu-btn:hover {
    background: var(--border-color);
    color: var(--text-color);
  }

  .profile-menu {
    position: absolute;
    bottom: 100%;
    right: 0;
    background: var(--bg-color);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-lg);
    box-shadow: 0 8px 16px var(--shadow-color);
    min-width: 200px;
    padding: var(--space-2);
    z-index: 1000;
    animation: slideUp 0.2s ease-out;
  }

  @keyframes slideUp {
    from {
      opacity: 0;
      transform: translateY(8px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }

  .menu-item {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: var(--space-2) var(--space-3);
    border-radius: var(--radius-md);
    text-decoration: none;
    color: var(--text-color);
    transition: background-color 0.2s;
    cursor: pointer;
  }

  .menu-item:hover {
    background-color: var(--border-color);
  }

  .menu-item-content {
    display: flex;
    align-items: center;
    gap: var(--space-2);
    font-size: 0.875rem;
  }

  .theme-toggle-item {
    cursor: default;
  }

  .theme-toggle-item:hover {
    background-color: transparent;
  }

  .menu-separator {
    height: 1px;
    background-color: var(--border-color);
    margin: var(--space-2) 0;
  }

  .signout-row {
    display: flex;
  }

  .sign-out-btn {
    background: none;
    border: none;
    color: var(--text-muted);
    cursor: pointer;
    padding: var(--space-2);
    border-radius: var(--radius-md);
    display: flex;
    align-items: center;
    gap: var(--space-2);
    transition: all 0.2s;
    font-size: 0.875rem;
    flex-shrink: 0;
    width: 100%;
    justify-content: flex-start;
  }

  .sign-out-btn:hover {
    background-color: var(--color-error-50);
    color: var(--color-error-600);
  }

  /* Mobile responsiveness */
  @media (max-width: 768px) {
    .sidebar {
      transform: translateX(-100%);
      transition: transform 0.3s ease, width 0.3s ease;
      z-index: 200;
    }

    .sidebar.mobile-open {
      transform: translateX(0);
    }
  }
</style>