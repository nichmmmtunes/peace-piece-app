<script lang="ts">
  import type { VideoClip } from './types';

  export let clips: VideoClip[] = [];
  export let selectedClip: VideoClip | null = null;
  export let activeTab: 'layers' | 'assets' = 'layers';
  export let showLayerPopup = false;
  export let popupStep: 'name' | 'content' = 'name';
  export let newLayerName = '';
  export let newLayerType: 'video' | 'image' | 'sticker' | 'music' | 'text' = 'video';
  export let newLayerContent = '';
  export let newLayerFile: File | null = null;
  export let currentTime = 0;

  let layerNameInput: HTMLInputElement;
  let textContentInput: HTMLTextAreaElement;
  let fileInput: HTMLInputElement;

  // Drag and drop state
  let draggedLayer: VideoClip | null = null;
  let dragOverIndex = -1;
  let isDragging = false;

  const layerTypes = [
    { value: 'video', label: 'Video', icon: '<svg width="24" height="18" viewBox="0 0 24 18" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M10.2766 12.9663L15.8028 9.435C15.9582 9.32604 16.0359 9.18104 16.0359 9C16.0359 8.81896 15.9582 8.67396 15.8028 8.565L10.2766 5.03375C10.1001 4.92 9.92656 4.90958 9.75594 5.0025C9.58531 5.09542 9.5 5.24281 9.5 5.44469V12.5553C9.5 12.7572 9.58531 12.9046 9.75594 12.9975C9.92656 13.0904 10.1001 13.08 10.2766 12.9663ZM2.76937 17.75C2.19396 17.75 1.71354 17.5573 1.32812 17.1719C0.942708 16.7865 0.75 16.306 0.75 15.7306V2.26937C0.75 1.69396 0.942708 1.21354 1.32812 0.828125C1.71354 0.442708 2.19396 0.25 2.76937 0.25H21.2306C21.806 0.25 22.2865 0.442708 22.6719 0.828125C23.0573 1.21354 23.25 1.69396 23.25 2.26937V15.7306C23.25 16.306 23.0573 16.7865 22.6719 17.1719C22.2865 17.5573 21.806 17.75 21.2306 17.75H2.76937ZM2.76937 16.5H21.2306C21.4231 16.5 21.5995 16.4199 21.7597 16.2597C21.9199 16.0995 22 15.9231 22 15.7306V2.26937C22 2.07687 21.9199 1.90052 21.7597 1.74031C21.5995 1.5801 21.4231 1.5 21.2306 1.5H2.76937C2.57687 1.5 2.40052 1.5801 2.24031 1.74031C2.0801 1.90052 2 2.07687 2 2.26937V15.7306C2 15.9231 2.0801 16.0995 2.24031 16.2597C2.40052 16.4199 2.57687 16.5 2.76937 16.5Z" fill="#1C1B1F"/></svg>', accept: 'video/*' },
    { value: 'image', label: 'Overlay Image', icon: '<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M2.01937 20C1.44396 20 0.963542 19.8073 0.578125 19.4219C0.192708 19.0365 0 18.556 0 17.9806V2.01937C0 1.44396 0.192708 0.963542 0.578125 0.578125C0.963542 0.192708 1.44396 0 2.01937 0H17.9806C18.556 0 19.0365 0.192708 19.4219 0.578125C19.8073 0.963542 20 1.44396 20 2.01937V17.9806C20 18.556 19.8073 19.0365 19.4219 19.4219C19.0365 19.8073 18.556 20 17.9806 20H2.01937ZM2.01937 18.75H17.9806C18.1731 18.75 18.3495 18.6699 18.5097 18.5097C18.6699 18.3495 18.75 18.1731 18.75 17.9806V2.01937C18.75 1.82687 18.6699 1.65052 18.5097 1.49031C18.3495 1.3301 18.1731 1.25 17.9806 1.25H2.01937C1.82687 1.25 1.65052 1.3301 1.49031 1.49031C1.3301 1.65052 1.25 1.82687 1.25 2.01937V17.9806C1.25 18.1731 1.3301 18.3495 1.49031 18.5097C1.65052 18.6699 1.82687 18.75 2.01937 18.75ZM5.38469 15.625H14.8078C15.0097 15.625 15.1571 15.5345 15.25 15.3534C15.3429 15.1724 15.3301 14.9936 15.2116 14.8172L12.6875 11.4256C12.5785 11.2908 12.444 11.2234 12.2838 11.2234C12.1233 11.2234 11.9886 11.2908 11.8797 11.4256L9.01437 15.0481L7.23063 12.8919C7.12167 12.7733 6.99115 12.7141 6.83906 12.7141C6.68677 12.7141 6.55615 12.7814 6.44719 12.9159L5.00469 14.8172C4.8701 14.9936 4.84927 15.1724 4.94219 15.3534C5.03531 15.5345 5.18281 15.625 5.38469 15.625Z" fill="#1C1B1F"/></svg>', accept: 'image/*' },
    { value: 'sticker', label: 'Sticker', icon: '<svg width="19" height="17" viewBox="0 0 19 17" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M1.70534 16.9993C1.24501 16.9993 0.860677 16.8451 0.552344 16.5368C0.24401 16.2284 0.0898438 15.8441 0.0898438 15.3838V4.61478C0.0898438 4.15445 0.24401 3.77011 0.552344 3.46178C0.860677 3.15345 1.24501 2.99928 1.70534 2.99928H5.97434L8.52434 0.449281C8.68601 0.287781 8.87451 0.207031 9.08984 0.207031C9.30518 0.207031 9.49368 0.287781 9.65534 0.449281L12.2053 2.99928H16.4743C16.9347 2.99928 17.319 3.15345 17.6273 3.46178C17.9357 3.77011 18.0898 4.15445 18.0898 4.61478V15.3838C18.0898 15.8441 17.9357 16.2284 17.6273 16.5368C17.319 16.8451 16.9347 16.9993 16.4743 16.9993H1.70534ZM1.70534 15.9993H16.4743C16.6283 15.9993 16.7694 15.9352 16.8976 15.807C17.0258 15.6789 17.0898 15.5378 17.0898 15.3838V4.61478C17.0898 4.46078 17.0258 4.3197 16.8976 4.19153C16.7694 4.06336 16.6283 3.99928 16.4743 3.99928H1.70534C1.55134 3.99928 1.41026 4.06336 1.28209 4.19153C1.15393 4.3197 1.08984 4.46078 1.08984 4.61478V15.3838C1.08984 15.5378 1.15393 15.6789 1.28209 15.807C1.41026 15.9352 1.55134 15.9993 1.70534 15.9993ZM8.30134 13.0378L6.87434 11.3128C6.78718 11.2179 6.68276 11.1705 6.56109 11.1705C6.43926 11.1705 6.33476 11.2244 6.24759 11.332L5.09359 12.853C4.98593 12.9942 4.96926 13.1372 5.04359 13.282C5.11809 13.4269 5.23609 13.4993 5.39759 13.4993H12.9361C13.0976 13.4993 13.2155 13.4269 13.2898 13.282C13.3642 13.1372 13.3539 12.9942 13.2591 12.853L11.2398 10.1398C11.1527 10.0319 11.045 9.97803 10.9168 9.97803C10.7885 9.97803 10.6808 10.0319 10.5936 10.1398L8.30134 13.0378ZM14.0128 8.99928C14.327 8.99928 14.5914 8.89195 14.8061 8.67728C15.0209 8.46245 15.1283 8.19795 15.1283 7.88378C15.1283 7.56978 15.0209 7.30536 14.8061 7.09053C14.5914 6.87586 14.327 6.76853 14.0128 6.76853C13.6988 6.76853 13.4344 6.87586 13.2196 7.09053C13.0049 7.30536 12.8976 7.56978 12.8976 7.88378C12.8976 8.19795 13.0049 8.46245 13.2196 8.67728C13.4344 8.89195 13.6988 8.99928 14.0128 8.99928ZM7.22834 2.99928H10.9513L9.08984 1.13778L7.22834 2.99928Z" fill="#1C1B1F"/></svg>', accept: 'image/png' },
    { value: 'music', label: 'Music', icon: '<svg width="19" height="15" viewBox="0 0 19 15" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M11.3009 14.9992C10.4759 14.9992 9.7696 14.7054 9.18211 14.1179C8.59461 13.5304 8.30086 12.8242 8.30086 11.9992C8.30086 11.1742 8.59461 10.4679 9.18211 9.88041C9.7696 9.29291 10.4759 8.99916 11.3009 8.99916C11.6842 8.99916 12.048 9.06741 12.3924 9.20391C12.7365 9.34041 13.0394 9.54524 13.3009 9.81841V1.49916C13.3009 1.27032 13.379 1.07849 13.5354 0.923656C13.6917 0.768822 13.8854 0.691406 14.1166 0.691406H17.3794C17.6104 0.691406 17.8024 0.768822 17.9556 0.923656C18.1089 1.07849 18.1856 1.27032 18.1856 1.49916V2.19141C18.1856 2.42024 18.1082 2.61207 17.9534 2.76691C17.7985 2.92174 17.6067 2.99916 17.3779 2.99916H14.3009V11.9992C14.3009 12.8242 14.0071 13.5304 13.4196 14.1179C12.8321 14.7054 12.1259 14.9992 11.3009 14.9992ZM4.03936 4.71266C3.16236 5.58949 2.45469 6.60132 1.91636 7.74816C1.37786 8.89499 1.07402 10.1222 1.00486 11.4299C0.997022 11.5851 0.945188 11.7187 0.849355 11.8309C0.753522 11.9431 0.634772 11.9992 0.493105 11.9992C0.338105 11.9992 0.216022 11.9389 0.126855 11.8184C0.0376884 11.6979 -0.0029782 11.5601 0.00485513 11.4049C0.0868551 9.95491 0.422355 8.59757 1.01136 7.33291C1.60052 6.06807 2.37202 4.95874 3.32586 4.00491C4.27969 3.05107 5.38577 2.28282 6.64411 1.70016C7.90244 1.11749 9.25661 0.785073 10.7066 0.702907C10.8618 0.69524 10.9996 0.735989 11.1201 0.825156C11.2406 0.914156 11.3009 1.03307 11.3009 1.18191C11.3009 1.33057 11.2448 1.45266 11.1326 1.54816C11.0204 1.64366 10.8868 1.69524 10.7316 1.70291C9.42394 1.77224 8.20086 2.07199 7.06236 2.60216C5.92402 3.13216 4.91636 3.83566 4.03936 4.71266ZM6.96061 7.65291C6.46311 8.15041 6.05794 8.72316 5.74511 9.37116C5.43227 10.0193 5.24511 10.7177 5.18361 11.4664C5.15861 11.6212 5.09819 11.7487 5.00236 11.8489C4.90652 11.9491 4.78777 11.9992 4.64611 11.9992C4.50444 11.9992 4.38677 11.9431 4.29311 11.8309C4.1996 11.7187 4.15669 11.5915 4.16436 11.4492C4.22969 10.562 4.44536 9.73732 4.81136 8.97516C5.17752 8.21299 5.65611 7.53641 6.24711 6.94541C6.83811 6.35424 7.51469 5.87566 8.27686 5.50966C9.03902 5.14366 9.86369 4.92799 10.7509 4.86266C10.8932 4.85499 11.0204 4.89749 11.1326 4.99016C11.2448 5.08282 11.3009 5.20074 11.3009 5.34391C11.3009 5.48707 11.2508 5.60632 11.1506 5.70166C11.0504 5.79699 10.9229 5.85707 10.7681 5.88191C10.0194 5.94341 9.32202 6.12957 8.67586 6.44041C8.02969 6.75141 7.45794 7.15557 6.96061 7.65291Z" fill="#1C1B1F"/></svg>', accept: 'audio/*' },
    { value: 'text', label: 'Text', icon: '<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M6.49586 13.3983L9.69211 5.18677C9.71178 5.12793 9.74803 5.0821 9.80086 5.04927C9.85353 5.0166 9.90953 5.00027 9.96886 5.00027H10.2051C10.2694 5.00027 10.3278 5.0166 10.3801 5.04927C10.4326 5.0821 10.4686 5.12793 10.4881 5.18677L13.7229 13.3965C13.7805 13.5528 13.7658 13.6926 13.6786 13.8158C13.5914 13.9388 13.4661 14.0003 13.3026 14.0003C13.2046 14.0003 13.1178 13.9768 13.0421 13.93C12.9664 13.8832 12.91 13.8104 12.8729 13.7118L11.9594 11.3925H8.23236L7.31886 13.7175C7.28169 13.8035 7.22853 13.8721 7.15936 13.9233C7.09019 13.9746 7.00944 14.0003 6.91711 14.0003C6.75294 14.0003 6.62728 13.9368 6.54011 13.8098C6.45294 13.6829 6.43819 13.5458 6.49586 13.3983ZM8.52861 10.5925H11.6516L10.1209 6.57327H10.0209L8.52861 10.5925ZM0.474609 18.808V16.1925C0.474609 15.9637 0.552026 15.7719 0.706859 15.617C0.861693 15.4622 1.05353 15.3848 1.28236 15.3848H2.09011V4.61577H1.27911C1.04928 4.61577 0.857776 4.53835 0.70461 4.38352C0.551276 4.22868 0.474609 4.03685 0.474609 3.80802V1.19252C0.474609 0.963682 0.552026 0.771848 0.706859 0.617015C0.861693 0.462182 1.05353 0.384766 1.28236 0.384766H3.89786C4.12669 0.384766 4.31853 0.462182 4.47336 0.617015C4.62819 0.771848 4.70561 0.963682 4.70561 1.19252V2.00027H15.4746V1.18927C15.4746 0.959432 15.552 0.767933 15.7069 0.614766C15.8617 0.461433 16.0535 0.384766 16.2824 0.384766H18.8979C19.1267 0.384766 19.3185 0.462182 19.4734 0.617015C19.6282 0.771848 19.7056 0.963682 19.7056 1.19252V3.80802C19.7056 4.03685 19.6282 4.22868 19.4734 4.38352C19.3185 4.53835 19.1267 4.61577 18.8979 4.61577H18.0901V15.3848H18.9011C19.1309 15.3848 19.3224 15.4622 19.4756 15.617C19.6289 15.7719 19.7056 15.9637 19.7056 16.1925V18.808C19.7056 19.0369 19.6282 19.2287 19.4734 19.3835C19.3185 19.5384 19.1267 19.6158 18.8979 19.6158H16.2824C16.0535 19.6158 15.8617 19.5384 15.7069 19.3835C15.552 19.2287 15.4746 19.0369 15.4746 18.808V18.0003H4.70561V18.8113C4.70561 19.0411 4.62819 19.2326 4.47336 19.3858C4.31853 19.5391 4.12669 19.6158 3.89786 19.6158H1.28236C1.05353 19.6158 0.861693 19.5384 0.706859 19.3835C0.552026 19.2287 0.474609 19.0369 0.474609 18.808ZM4.70561 17.0003H15.4746V16.1893C15.4746 15.9594 15.552 15.7679 15.7069 15.6148C15.8617 15.4614 16.0535 15.3848 16.2824 15.3848H17.0901V4.61577H16.2791C16.0493 4.61577 15.8578 4.53835 15.7046 4.38352C15.5513 4.22868 15.4746 4.03685 15.4746 3.80802V3.00027H4.70561V3.81127C4.70561 4.0411 4.62819 4.2326 4.47336 4.38577C4.31853 4.5391 4.12669 4.61577 3.89786 4.61577H3.09011V15.3848H3.90111C4.13094 15.3848 4.32244 15.4622 4.47561 15.617C4.62894 15.7719 4.70561 15.9637 4.70561 16.1925V17.0003Z" fill="#1C1B1F"/></svg>', accept: '' }
  ];

  // Event dispatchers
  import { createEventDispatcher } from 'svelte';
  const dispatch = createEventDispatcher();

  function selectClip(clip: VideoClip) {
    dispatch('selectClip', clip);
  }

  function deleteClip(clipId: string) {
    dispatch('deleteClip', clipId);
  }

  function reorderLayers(fromIndex: number, toIndex: number) {
    dispatch('reorderLayers', { fromIndex, toIndex });
  }

  // Drag and drop functions
  function handleDragStart(event: DragEvent, clip: VideoClip, index: number) {
    if (!event.dataTransfer) return;
    
    draggedLayer = clip;
    isDragging = true;
    
    event.dataTransfer.effectAllowed = 'move';
    event.dataTransfer.setData('text/plain', clip.id);
    
    // Add visual feedback
    const target = event.target as HTMLElement;
    target.style.opacity = '0.5';
  }

  function handleDragEnd(event: DragEvent) {
    isDragging = false;
    draggedLayer = null;
    dragOverIndex = -1;
    
    // Reset visual feedback
    const target = event.target as HTMLElement;
    target.style.opacity = '1';
  }

  function handleDragOver(event: DragEvent, index: number) {
    event.preventDefault();
    if (!draggedLayer) return;
    
    dragOverIndex = index;
    
    if (event.dataTransfer) {
      event.dataTransfer.dropEffect = 'move';
    }
  }

  function handleDragLeave(event: DragEvent) {
    // Only clear dragOverIndex if we're leaving the entire layer item
    const target = event.target as HTMLElement;
    const relatedTarget = event.relatedTarget as HTMLElement;
    
    if (!target.contains(relatedTarget)) {
      dragOverIndex = -1;
    }
  }

  function handleDrop(event: DragEvent, dropIndex: number) {
    event.preventDefault();
    
    if (!draggedLayer) return;
    
    const draggedIndex = clips.findIndex(clip => clip.id === draggedLayer!.id);
    
    if (draggedIndex !== -1 && draggedIndex !== dropIndex) {
      reorderLayers(draggedIndex, dropIndex);
    }
    
    draggedLayer = null;
    dragOverIndex = -1;
    isDragging = false;
  }

  function openLayerPopup() {
    showLayerPopup = true;
    popupStep = 'name';
    newLayerName = '';
    newLayerType = 'video';
    newLayerContent = '';
    newLayerFile = null;
    
    setTimeout(() => {
      if (layerNameInput) {
        layerNameInput.focus();
      }
    }, 100);
  }

  function closeLayerPopup() {
    showLayerPopup = false;
    popupStep = 'name';
    newLayerName = '';
    newLayerType = 'video';
    newLayerContent = '';
    newLayerFile = null;
  }

  function proceedToContent() {
    if (!newLayerName.trim()) return;
    
    popupStep = 'content';
    
    setTimeout(() => {
      if (newLayerType === 'text' && textContentInput) {
        textContentInput.focus();
      } else if (newLayerType !== 'text' && fileInput) {
        fileInput.click();
      }
    }, 100);
  }

  function handleLayerFileUpload(event: Event) {
    const target = event.target as HTMLInputElement;
    if (target.files && target.files[0]) {
      newLayerFile = target.files[0];
    }
  }

  async function createLayer() {
    if (!newLayerName.trim()) return;
    
    if (newLayerType === 'text' && !newLayerContent.trim()) return;
    if (newLayerType !== 'text' && !newLayerFile) return;

    const layerTypeConfig = layerTypes.find(t => t.value === newLayerType);
    let duration = 10;
    let url: string | undefined = undefined;

    if (newLayerFile) {
      url = URL.createObjectURL(newLayerFile);
      
      if (newLayerType === 'video' || newLayerType === 'music') {
        const media = document.createElement(newLayerType === 'video' ? 'video' : 'audio');
        media.onloadedmetadata = () => {
          duration = media.duration;
        };
        media.src = url;
      }
    }

    const newClip: VideoClip = {
      id: Math.random().toString(36).substr(2, 9),
      name: newLayerName,
      type: newLayerType === 'music' ? 'audio' : newLayerType === 'sticker' ? 'image' : newLayerType,
      icon: layerTypeConfig?.icon || '<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M6.40602 13.3983L9.60227 5.18677C9.62193 5.12793 9.65818 5.0821 9.71102 5.04927C9.76368 5.0166 9.81968 5.00027 9.87902 5.00027H10.1153C10.1796 5.00027 10.2379 5.0166 10.2903 5.04927C10.3428 5.0821 10.3788 5.12793 10.3983 5.18677L13.633 13.3965C13.6907 13.5528 13.6759 13.6926 13.5888 13.8158C13.5016 13.9388 13.3763 14.0003 13.2128 14.0003C13.1148 14.0003 13.0279 13.9768 12.9523 13.93C12.8766 13.8832 12.8202 13.8104 12.783 13.7118L11.8695 11.3925H8.14252L7.22902 13.7175C7.19185 13.8035 7.13868 13.8721 7.06952 13.9233C7.00035 13.9746 6.9196 14.0003 6.82727 14.0003C6.6631 14.0003 6.53743 13.9368 6.45027 13.8098C6.3631 13.6829 6.34835 13.5458 6.40602 13.3983ZM8.43877 10.5925H11.5618L10.031 6.57327H9.93102L8.43877 10.5925ZM0.384766 18.808V16.1925C0.384766 15.9637 0.462182 15.7719 0.617016 15.617C0.771849 15.4622 0.963682 15.3848 1.19252 15.3848H2.00027V4.61577H1.18927C0.959432 4.61577 0.767932 4.53835 0.614766 4.38352C0.461432 4.22868 0.384766 4.03685 0.384766 3.80802V1.19252C0.384766 0.963682 0.462182 0.771848 0.617016 0.617015C0.771849 0.462182 0.963682 0.384766 1.19252 0.384766H3.80802C4.03685 0.384766 4.22868 0.462182 4.38352 0.617015C4.53835 0.771848 4.61577 0.963682 4.61577 1.19252V2.00027H15.3848V1.18927C15.3848 0.959432 15.4622 0.767933 15.617 0.614766C15.7719 0.461433 15.9637 0.384766 16.1925 0.384766H18.808C19.0369 0.384766 19.2287 0.462182 19.3835 0.617015C19.5384 0.771848 19.6158 0.963682 19.6158 1.19252V3.80802C19.6158 4.03685 19.5384 4.22868 19.3835 4.38352C19.2287 4.53835 19.0369 4.61577 18.808 4.61577H18.0003V15.3848H18.8113C19.0411 15.3848 19.2326 15.4622 19.3858 15.617C19.5391 15.7719 19.6158 15.9637 19.6158 16.1925V18.808C19.6158 19.0369 19.5384 19.2287 19.3835 19.3835C19.2287 19.5384 19.0369 19.6158 18.808 19.6158H16.1925C15.9637 19.6158 15.7719 19.5384 15.617 19.3835C15.4622 19.2287 15.3848 19.0369 15.3848 18.808V18.0003H4.61577V18.8113C4.61577 19.0411 4.53835 19.2326 4.38352 19.3858C4.22868 19.5391 4.03685 19.6158 3.80802 19.6158H1.19252C0.963682 19.6158 0.771849 19.5384 0.617016 19.3835C0.462182 19.2287 0.384766 19.0369 0.384766 18.808ZM4.61577 17.0003H15.3848V16.1893C15.3848 15.9594 15.4622 15.7679 15.617 15.6148C15.7719 15.4614 15.9637 15.3848 16.1925 15.3848H17.0003V4.61577H16.1893C15.9594 4.61577 15.7679 4.53835 15.6148 4.38352C15.4614 4.22868 15.3848 4.03685 15.3848 3.80802V3.00027H4.61577V3.81127C4.61577 4.0411 4.53835 4.2326 4.38352 4.38577C4.22868 4.5391 4.03685 4.61577 3.80802 4.61577H3.00027V15.3848H3.81127C4.0411 15.3848 4.2326 15.4622 4.38577 15.617C4.5391 15.7719 4.61577 15.9637 4.61577 16.1925V17.0003Z" fill="#1C1B1F"/></svg>',
      layer: clips.length,
      timelineStart: currentTime,
      timelineEnd: currentTime + duration,
      duration: duration,
      contentStartTime: 0,
      contentEndTime: duration,
      file: newLayerFile,
      url: url,
      content: newLayerType === 'text' ? newLayerContent : undefined,
      // Set proper sampleData type for correct identification
      sampleData: {
        type: newLayerType === 'sticker' ? 'sticker' : 
              newLayerType === 'image' ? 'image' : 
              newLayerType === 'music' ? 'audio' : newLayerType
      }
    };
    
    dispatch('createLayer', newClip);
    closeLayerPopup();
  }

  function handleFileUpload(event: Event) {
    const target = event.target as HTMLInputElement;
    if (target.files) {
      Array.from(target.files).forEach(file => {
        dispatch('addVideoFile', file);
      });
    }
  }

  function handlePopupKeyDown(event: KeyboardEvent) {
    if (event.key === 'Enter') {
      if (popupStep === 'name') {
        proceedToContent();
      } else if (popupStep === 'content' && newLayerType === 'text') {
        createLayer();
      }
    }
  }

  $: selectedLayerType = layerTypes.find(t => t.value === newLayerType);

  // Sort clips by layer order for display (highest layer number at top)
  $: sortedClips = [...clips].sort((a, b) => b.layer - a.layer);
</script>

<div class="left-sidebar">
  <!-- Tab Navigation -->
  <div class="tab-nav">
    <button 
      class="tab-btn" 
      class:active={activeTab === 'layers'}
      on:click={() => activeTab = 'layers'}
    >
      Layers
    </button>
    <button 
      class="tab-btn" 
      class:active={activeTab === 'assets'}
      on:click={() => activeTab = 'assets'}
    >
      Assets
    </button>
  </div>

  <!-- Tab Content -->
  <div class="tab-content">
    {#if activeTab === 'layers'}
      <div class="layers-panel">
        <div class="layers-header">
          <button class="add-layer-btn" on:click={openLayerPopup}>
            + Add Layer
          </button>
          <div class="layer-info">
            <span class="layer-count">{clips.length} layers</span>
            <span class="layer-hint">Drag to reorder</span>
          </div>
        </div>
        
        <div class="layers-list">
          {#each sortedClips as clip, index}
            <div 
              class="layer-item" 
              class:selected={selectedClip?.id === clip.id}
              class:dragging={isDragging && draggedLayer?.id === clip.id}
              class:drag-over={dragOverIndex === index}
              draggable="true"
              on:click={() => selectClip(clip)}
              on:dragstart={(e) => handleDragStart(e, clip, index)}
              on:dragend={handleDragEnd}
              on:dragover={(e) => handleDragOver(e, index)}
              on:dragleave={handleDragLeave}
              on:drop={(e) => handleDrop(e, index)}
            >
              <div class="layer-drag-handle" title="Drag to reorder">
                <div class="drag-dots">
                  <div class="dot"></div>
                  <div class="dot"></div>
                  <div class="dot"></div>
                  <div class="dot"></div>
                  <div class="dot"></div>
                  <div class="dot"></div>
                </div>
              </div>
              
              <span class="layer-icon">{@html clip.icon}</span>
              
              <div class="layer-content">
                <span class="layer-name">{clip.name}</span>
                <span class="layer-info-text">Layer {clip.layer}</span>
              </div>
              
              <button 
                class="delete-layer-btn"
                on:click|stopPropagation={() => deleteClip(clip.id)}
                title="Delete layer"
              >
                ×
              </button>
            </div>
          {/each}
          
          {#if clips.length === 0}
            <div class="empty-layers">
              <div class="empty-icon">
                <svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <path d="M6.49586 13.3983L9.69211 5.18677C9.71178 5.12793 9.74803 5.0821 9.80086 5.04927C9.85353 5.0166 9.90953 5.00027 9.96886 5.00027H10.2051C10.2694 5.00027 10.3278 5.0166 10.3801 5.04927C10.4326 5.0821 10.4686 5.12793 10.4881 5.18677L13.7229 13.3965C13.7805 13.5528 13.7658 13.6926 13.6786 13.8158C13.5914 13.9388 13.4661 14.0003 13.3026 14.0003C13.2046 14.0003 13.1178 13.9768 13.0421 13.93C12.9664 13.8832 12.91 13.8104 12.8729 13.7118L11.9594 11.3925H8.23236L7.31886 13.7175C7.28169 13.8035 7.22853 13.8721 7.15936 13.9233C7.09019 13.9746 7.00944 14.0003 6.91711 14.0003C6.75294 14.0003 6.62728 13.9368 6.54011 13.8098C6.45294 13.6829 6.43819 13.5458 6.49586 13.3983ZM8.52861 10.5925H11.6516L10.1209 6.57327H10.0209L8.52861 10.5925ZM0.474609 18.808V16.1925C0.474609 15.9637 0.552026 15.7719 0.706859 15.617C0.861693 15.4622 1.05353 15.3848 1.28236 15.3848H2.09011V4.61577H1.27911C1.04928 4.61577 0.857776 4.53835 0.70461 4.38352C0.551276 4.22868 0.474609 4.03685 0.474609 3.80802V1.19252C0.474609 0.963682 0.552026 0.771848 0.706859 0.617015C0.861693 0.462182 1.05353 0.384766 1.28236 0.384766H3.89786C4.12669 0.384766 4.31853 0.462182 4.47336 0.617015C4.62819 0.771848 4.70561 0.963682 4.70561 1.19252V2.00027H15.4746V1.18927C15.4746 0.959432 15.552 0.767933 15.7069 0.614766C15.8617 0.461433 16.0535 0.384766 16.2824 0.384766H18.8979C19.1267 0.384766 19.3185 0.462182 19.4734 0.617015C19.6282 0.771848 19.7056 0.963682 19.7056 1.19252V3.80802C19.7056 4.03685 19.6282 4.22868 19.4734 4.38352C19.3185 4.53835 19.1267 4.61577 18.8979 4.61577H18.0901V15.3848H18.9011C19.1309 15.3848 19.3224 15.4622 19.4756 15.617C19.6289 15.7719 19.7056 15.9637 19.7056 16.1925V18.808C19.7056 19.0369 19.6282 19.2287 19.4734 19.3835C19.3185 19.5384 19.1267 19.6158 18.8979 19.6158H16.2824C16.0535 19.6158 15.8617 19.5384 15.7069 19.3835C15.552 19.2287 15.4746 19.0369 15.4746 18.808V18.0003H4.70561V18.8113C4.70561 19.0411 4.62819 19.2326 4.47336 19.3858C4.31853 19.5391 4.12669 19.6158 3.89786 19.6158H1.28236C1.05353 19.6158 0.861693 19.5384 0.706859 19.3835C0.552026 19.2287 0.474609 19.0369 0.474609 18.808ZM4.70561 17.0003H15.4746V16.1893C15.4746 15.9594 15.552 15.7679 15.7069 15.6148C15.8617 15.4614 16.0535 15.3848 16.2824 15.3848H17.0901V4.61577H16.2791C16.0493 4.61577 15.8578 4.53835 15.7046 4.38352C15.5513 4.22868 15.4746 4.03685 15.4746 3.80802V3.00027H4.70561V3.81127C4.70561 4.0411 4.62819 4.2326 4.47336 4.38577C4.31853 4.5391 4.12669 4.61577 3.89786 4.61577H3.09011V15.3848H3.90111C4.13094 15.3848 4.32244 15.4622 4.47561 15.617C4.62894 15.7719 4.70561 15.9637 4.70561 16.1925V17.0003Z" fill="#1C1B1F"/>
                </svg>
              </div>
              <div class="empty-text">No layers yet</div>
              <div class="empty-hint">Click "Add Layer" to get started</div>
            </div>
          {/if}
        </div>
      </div>
    {:else}
      <div class="assets-panel">
        <input
          type="file"
          multiple
          accept="video/*,image/*,audio/*"
          on:change={handleFileUpload}
          id="asset-upload"
          class="file-input"
        />
        <label for="asset-upload" class="upload-btn">
          + Add Assets
        </label>
      </div>
    {/if}
  </div>
</div>

<!-- Layer Creation Popup -->
{#if showLayerPopup}
  <div class="popup-overlay" on:click={closeLayerPopup}>
    <div class="popup-content" on:click|stopPropagation on:keydown={handlePopupKeyDown}>
      {#if popupStep === 'name'}
        <div class="popup-header">
          <h3>Create New Layer</h3>
          <button class="popup-close" on:click={closeLayerPopup}>×</button>
        </div>
        
        <div class="popup-body">
          <div class="form-group">
            <label for="layer-name">Layer Name</label>
            <input
              id="layer-name"
              type="text"
              bind:value={newLayerName}
              bind:this={layerNameInput}
              class="popup-input"
              placeholder="Enter layer name..."
            />
          </div>
          
          <div class="form-group">
            <label>Layer Type</label>
            <div class="layer-type-grid">
              {#each layerTypes as layerType}
                <button
                  class="layer-type-btn"
                  class:selected={newLayerType === layerType.value}
                  on:click={() => newLayerType = layerType.value}
                >
                  <span class="layer-type-icon">{@html layerType.icon}</span>
                  <span class="layer-type-label">{layerType.label}</span>
                </button>
              {/each}
            </div>
          </div>
        </div>
        
        <div class="popup-footer">
          <button class="popup-btn secondary" on:click={closeLayerPopup}>Cancel</button>
          <button 
            class="popup-btn primary" 
            on:click={proceedToContent}
            disabled={!newLayerName.trim()}
          >
            Next
          </button>
        </div>
      {:else if popupStep === 'content'}
        <div class="popup-header">
          <h3>Add {selectedLayerType?.label} Content</h3>
          <button class="popup-close" on:click={closeLayerPopup}>×</button>
        </div>
        
        <div class="popup-body">
          <div class="content-preview">
            <div class="content-icon">{@html selectedLayerType?.icon}</div>
            <div class="content-name">{newLayerName}</div>
          </div>
          
          {#if newLayerType === 'text'}
            <div class="form-group">
              <label for="text-content">Text Content</label>
              <textarea
                id="text-content"
                bind:value={newLayerContent}
                bind:this={textContentInput}
                class="popup-textarea"
                placeholder="Enter your text content..."
                rows="4"
              ></textarea>
            </div>
          {:else}
            <div class="form-group">
              <label>Upload {selectedLayerType?.label}</label>
              <input
                type="file"
                accept={selectedLayerType?.accept}
                on:change={handleLayerFileUpload}
                bind:this={fileInput}
                class="file-input"
                id="layer-file-input"
              />
              <label for="layer-file-input" class="file-upload-btn">
                {#if newLayerFile}
                  <span class="file-name">✓ {newLayerFile.name}</span>
                {:else}
                  <span class="upload-text">📁 Choose {selectedLayerType?.label} File</span>
                {/if}
              </label>
            </div>
          {/if}
        </div>
        
        <div class="popup-footer">
          <button class="popup-btn secondary" on:click={() => popupStep = 'name'}>Back</button>
          <button 
            class="popup-btn primary" 
            on:click={createLayer}
            disabled={newLayerType === 'text' ? !newLayerContent.trim() : !newLayerFile}
          >
            Add Layer
          </button>
        </div>
      {/if}
    </div>
  </div>
{/if}

<style>
  /* Left Sidebar */
  .left-sidebar {
    width: 100%;
    background: var(--color-neutral-100);
    border-right: 1px solid #d0d0d0;
    display: flex;
    flex-direction: column;
    height: 100%;
  }

  .tab-nav {
    display: flex;
    border-bottom: 1px solid #d0d0d0;
    flex-shrink: 0;
  }

  .tab-btn {
    flex: 1;
    padding: 0.75rem;
    background: none;
    border: none;
    cursor: pointer;
    font-size: 0.9rem;
    color: #666;
    border-bottom: 2px solid transparent;
    border-radius: 0px;
  }

  button.tab-btn:focus {
    outline: none;
  }

  .tab-btn.active {
    color: var(--color-primary-600);
    border-bottom-color: var(--color-primary-500);
    background-color: #FBFBFB;
  }

  .tab-content {
    flex: 1;
    padding: 1rem;
    overflow-y: auto;
    background: #FBFBFB;
  }

  .layers-panel {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
    height: 100%;
  }

  .layers-header {
    margin-bottom: 0.5rem;
  }

  .add-layer-btn {
    width: 100%;
    padding: 0.5rem;
    background: black;
    color: white;
    border: none;
    border-radius: 100px;
    cursor: pointer;
    font-size: 0.8rem;
    margin-bottom: 0.5rem;
    height: 45.5px;
  }

  .layer-info {
    display: flex;
    justify-content: space-between;
    align-items: center;
    font-size: 0.7rem;
    color: #666;
  }

  .layer-count {
    font-weight: 500;
  }

  .layer-hint {
    opacity: 0.7;
  }

  .layers-list {
    flex: 1;
    display: flex;
    flex-direction: column;
    gap: 2px;
  }

  .layer-item {
    display: flex;
    align-items: center;
    gap: 0.1rem;
    padding: 0.5rem;
    border-radius: 4px;
    cursor: pointer;
    transition: all 0.2s;
    position: relative;
    border: 2px solid transparent;
    background: var(--color-neutral-100);
  }

  .layer-item:hover {
    background: var(--color-neutral-100);
  }

  .layer-item.selected {
    background: var(--color-neutral-200);
  }

  .layer-item.dragging {
    opacity: 0.5;
    transform: rotate(2deg);
    z-index: 1000;
  }

  .layer-item.drag-over {
    border-color: #007AFF;
    border-top: solid 2px;
    border-left: 0px;
    border-right: 0px;
    border-bottom: 0px;
    background: #f8f9ff;
    transform: translateY(-2px);
    box-shadow: 0 4px 8px rgba(0, 122, 255, 0.2);
  }

  .layer-drag-handle {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 16px;
    height: 16px;
    cursor: grab;
    opacity: 0.5;
    transition: opacity 0.2s;
  }

  .layer-item:hover .layer-drag-handle {
    opacity: 1;
  }

  .layer-drag-handle:active {
    cursor: grabbing;
  }

  .drag-dots {
    display: grid;
    grid-template-columns: repeat(2, 2px);
    grid-template-rows: repeat(3, 2px);
    gap: 3px;
  }

  .dot {
    width: 3px;
    height: 3px;
    background: var(--color-neutral-800);
    border-radius: 50%;
  }

  .layer-item.selected .dot {
    background: var(--color-neutral-900);
  }

  .layer-icon {
    font-size: 0.9rem;
    flex-shrink: 0;
  }

  .layer-content {
    flex: 1;
    display: flex;
    flex-direction: column;
    gap: 2px;
    overflow: hidden;
    padding-left: 8px;
  }

  .layer-name {
    font-size: 12px;
    font-weight: 500;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    line-height: 1;
  }

  .layer-info-text {
    font-size: 10px;
    opacity: 0.7;
  }

  .layer-item.selected .layer-info-text {
    opacity: 0.9;
  }

  .delete-layer-btn {
    background: none;
    border: none;
    color: #999;
    cursor: pointer;
    font-size: 1.2rem;
    padding: 0;
    width: 10px;
    height: 10px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 50%;
    transition: all 0.2s;
    flex-shrink: 0;
  }

  .delete-layer-btn:hover {
    color: var(--color-accent-600);
  }

  .empty-layers {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 2rem 1rem;
    text-align: center;
    color: #666;
    flex: 1;
  }

  .empty-icon {
    font-size: 2rem;
    margin-bottom: 0.5rem;
    opacity: 0.5;
  }

  .empty-text {
    font-size: 0.9rem;
    font-weight: 500;
    margin-bottom: 0.25rem;
  }

  .empty-hint {
    font-size: 0.8rem;
    opacity: 0.7;
  }

  .assets-panel {
    display: flex;
    flex-direction: column;
  }

  .file-input {
    display: none;
  }

  .upload-btn {
    display: block;
    padding: 0.75rem;
    background: black;
    color: white;
    text-align: center;
    border-radius: 100px;
    cursor: pointer;
    font-size: 0.9rem;
  }

  /* Popup Styles */
  .popup-overlay {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.5);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 1000;
    backdrop-filter: blur(4px);
  }

  .popup-content {
    background: white;
    border-radius: 8px;
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.2);
    width: 90%;
    max-width: 500px;
    max-height: 80vh;
    overflow: hidden;
    display: flex;
    flex-direction: column;
  }

  .popup-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 1.5rem;
    border-bottom: 1px solid #e0e0e0;
  }

  .popup-header h3 {
    margin: 0;
    font-size: 1.2rem;
    font-weight: 500;
  }

  .popup-close {
    background: none;
    border: none;
    font-size: 22px;
    cursor: pointer;
    color: #666;
    padding: 0;
    width: 32px;
    height: 32px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 50%;
    transition: background 0.2s;
  }

  .popup-close:hover {
    background: #f0f0f0;
  }

  .popup-body {
    flex: 1;
    padding: 1.5rem;
    overflow-y: auto;
  }

  .form-group {
    margin-bottom: 1.5rem;
  }

  .form-group label {
    display: block;
    font-size: 0.9rem;
    font-weight: 500;
    color: #333;
    margin-bottom: 0.5rem;
  }

  .popup-input {
    width: 100%;
    padding: 0.75rem;
    border: 2px solid #e0e0e0;
    border-radius: 6px;
    font-size: 1rem;
    transition: border-color 0.2s;
  }

  .popup-input:focus {
    outline: none;
    border-color: #007AFF;
  }

  .popup-textarea {
    width: 100%;
    padding: 0.75rem;
    border: 2px solid #e0e0e0;
    border-radius: 6px;
    font-size: 1rem;
    resize: vertical;
    min-height: 100px;
    font-family: inherit;
    transition: border-color 0.2s;
  }

  .popup-textarea:focus {
    outline: none;
    border-color: #007AFF;
  }

  .layer-type-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
    gap: 0.75rem;
  }

  .layer-type-btn {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 0.5rem;
    padding: 1rem;
    border: 2px solid #e0e0e0;
    border-radius: 8px;
    background: white;
    cursor: pointer;
    transition: all 0.2s;
    color: black;
  }

  .layer-type-btn:hover {
    border-color: #007AFF;
    background: #f8f9ff;
  }

  .layer-type-btn.selected {
    border-color: #007AFF;
    background: #007AFF;
    color: white;
  }

  .layer-type-icon {
    font-size: 22px;
  }

  .layer-type-label {
    font-size: 0.8rem;
    font-weight: 500;
    text-align: center;
  }

  .content-preview {
    display: flex;
    align-items: center;
    gap: 1rem;
    padding: 1rem;
    background: #f8f9ff;
    border-radius: 8px;
    margin-bottom: 1.5rem;
  }

  .content-icon {
    font-size: 2rem;
  }

  .content-name {
    font-size: 1.1rem;
    font-weight: 500;
    color: #333;
  }

  .file-upload-btn {
    display: block;
    width: 100%;
    padding: 1rem;
    border: 2px dashed #d0d0d0;
    border-radius: 8px;
    text-align: center;
    cursor: pointer;
    transition: all 0.2s;
    background: #fafafa;
  }

  .file-upload-btn:hover {
    border-color: #007AFF;
    background: #f8f9ff;
  }

  .file-name {
    color: #007AFF;
    font-weight: 500;
  }

  .upload-text {
    color: #666;
  }

  .popup-footer {
    display: flex;
    gap: 1rem;
    padding: 1.5rem;
    border-top: 1px solid #e0e0e0;
    justify-content: flex-end;
  }

  .popup-btn {
    padding: 0.75rem 1.5rem;
    border: none;
    border-radius: 6px;
    font-size: 0.9rem;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.2s;
  }

  .popup-btn.secondary {
    background: #f0f0f0;
    color: #666;
  }

  .popup-btn.secondary:hover {
    background: #e0e0e0;
  }

  .popup-btn.primary {
    background: #007AFF;
    color: white;
  }

  .popup-btn.primary:hover {
    background: #0056CC;
  }

  .popup-btn:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .popup-btn:disabled:hover {
    background: #007AFF;
  }

  .popup-btn.secondary:disabled:hover {
    background: #f0f0f0;
  }
</style>