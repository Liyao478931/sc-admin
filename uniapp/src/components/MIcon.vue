<template>
  <view class="m-icon" :style="{ width: size + 'px', height: size + 'px' }">
    <!-- #ifdef MP-WEIXIN -->
    <image v-if="iconSrc" :src="iconSrc" :style="{ width: size + 'px', height: size + 'px' }" mode="aspectFit" />
    <!-- #endif -->
    <!-- #ifndef MP-WEIXIN -->
    <svg
      :viewBox="viewBox"
      :width="size"
      :height="size"
      fill="none"
      :stroke="strokeVal"
      :stroke-width="weight"
      stroke-linecap="round"
      stroke-linejoin="round"
      :style="svgStyle"
    >
      <defs v-if="g1 && g2">
        <linearGradient :id="gid" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" :stop-color="g1" />
          <stop offset="100%" :stop-color="g2" />
        </linearGradient>
      </defs>
      <template v-for="(p, i) in paths" :key="i">
        <path v-if="p.kind === 'path'" :d="p.d" />
        <circle v-else-if="p.kind === 'circle'" :cx="p.cx" :cy="p.cy" :r="p.r" />
        <rect v-else-if="p.kind === 'rect'" :x="p.x" :y="p.y" :width="p.w" :height="p.h" :rx="p.rx || 0" :ry="p.ry || 0" />
        <line v-else-if="p.kind === 'line'" :x1="p.x1" :y1="p.y1" :x2="p.x2" :y2="p.y2" />
        <polyline v-else-if="p.kind === 'polyline'" :points="p.points" />
      </template>
    </svg>
    <!-- #endif -->
  </view>
</template>

<script>
// ============================================================================
// 文件路径：src/components/MIcon.vue
// 现代化线性 SVG 图标组件（Lucide 风格，24x24 viewBox，stroke=currentColor）
// 支持：name 图标名 / size 尺寸 / color 颜色 / g1+g2 渐变（可选）
// 用法：<MIcon name="gear" :size="22" color="#fff" />
//       <MIcon name="clipboard" :size="22" g1="#4F46E5" g2="#7C6FF0" />
// ============================================================================
const ICONS = {
  // —— 常用 ——
  gear: [
    { kind: 'path', d: 'M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z' },
    { kind: 'circle', cx: 12, cy: 12, r: 3 }
  ],
  clipboard: [
    { kind: 'rect', x: 8, y: 2, w: 8, h: 4, rx: 1 },
    { kind: 'path', d: 'M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2' },
    { kind: 'path', d: 'M12 11h4' }, { kind: 'path', d: 'M12 16h4' },
    { kind: 'path', d: 'M8 11h.01' }, { kind: 'path', d: 'M8 16h.01' }
  ],
  factory: [
    { kind: 'path', d: 'M2 20a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V8l-7 5V8l-7 5V4a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2v16z' },
    { kind: 'path', d: 'M17 18h1' }, { kind: 'path', d: 'M12 18h1' }, { kind: 'path', d: 'M7 18h1' }
  ],
  inbox: [
    { kind: 'path', d: 'M22 12h-6l-2 3h-4l-2-3H2' },
    { kind: 'path', d: 'M5.45 5.11L2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z' }
  ],
  alert: [
    { kind: 'path', d: 'M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z' },
    { kind: 'path', d: 'M12 9v4' }, { kind: 'path', d: 'M12 17h.01' }
  ],
  trend: [
    { kind: 'path', d: 'M23 6l-9.5 9.5-5-5L1 18' }, { kind: 'path', d: 'M17 6h6v6' }
  ],
  chart: [
    { kind: 'path', d: 'M12 20V10' }, { kind: 'path', d: 'M18 20V4' }, { kind: 'path', d: 'M6 20v-4' }
  ],
  file: [
    { kind: 'path', d: 'M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z' },
    { kind: 'path', d: 'M14 2v6h6' }, { kind: 'path', d: 'M16 13H8' }, { kind: 'path', d: 'M16 17H8' }, { kind: 'path', d: 'M10 9H8' }
  ],
  zap: [
    { kind: 'path', d: 'M13 2L3 14h9l-1 8 10-12h-9l1-8z' }
  ],
  scale: [
    { kind: 'path', d: 'M16 16l3-8 3 8c-.87.65-1.92 1-3 1s-2.13-.35-3-1Z' },
    { kind: 'path', d: 'M2 16l3-8 3 8c-.87.65-1.92 1-3 1s-2.13-.35-3-1Z' },
    { kind: 'path', d: 'M7 21h10' }, { kind: 'path', d: 'M12 3v18' },
    { kind: 'path', d: 'M3 7h2c2 0 5-1 7-2 2 1 5 2 7 2h2' }
  ],
  trophy: [
    { kind: 'path', d: 'M6 9H4.5a2.5 2.5 0 0 1 0-5H6' },
    { kind: 'path', d: 'M18 9h1.5a2.5 2.5 0 0 0 0-5H18' },
    { kind: 'path', d: 'M4 22h16' },
    { kind: 'path', d: 'M10 14.66V17c0 .55-.47.98-.97 1.21C7.85 18.75 7 20.24 7 22' },
    { kind: 'path', d: 'M14 14.66V17c0 .55.47.98.97 1.21C16.15 18.75 17 20.24 17 22' },
    { kind: 'path', d: 'M18 2H6v7a6 6 0 0 0 12 0V2Z' }
  ],
  medal: [
    { kind: 'circle', cx: 12, cy: 8, r: 6 },
    { kind: 'path', d: 'M15.477 12.89L17 22l-5-3-5 3 1.523-9.11' }
  ],
  shield: [
    { kind: 'path', d: 'M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z' }
  ],
  book: [
    { kind: 'path', d: 'M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z' },
    { kind: 'path', d: 'M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z' }
  ],
  wrench: [
    { kind: 'path', d: 'M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z' }
  ],
  megaphone: [
    { kind: 'path', d: 'M3 11l18-5v12L3 14v-3z' }, { kind: 'path', d: 'M11.6 16.8a3 3 0 1 1-5.8-1.6' }
  ],
  'chevron-left': [
    { kind: 'path', d: 'M15 18l-6-6 6-6' }
  ],
  'chevron-right': [
    { kind: 'path', d: 'M9 18l6-6-6-6' }
  ],
  mail: [
    { kind: 'rect', x: 2, y: 4, w: 20, h: 16, rx: 2 },
    { kind: 'path', d: 'M22 7l-10 5L2 7' }
  ],
  bell: [
    { kind: 'path', d: 'M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9' },
    { kind: 'path', d: 'M13.73 21a2 2 0 0 1-3.46 0' }
  ],
  search: [
    { kind: 'circle', cx: 11, cy: 11, r: 8 },
    { kind: 'path', d: 'M21 21l-4.35-4.35' }
  ],
  close: [
    { kind: 'path', d: 'M18 6L6 18' }, { kind: 'path', d: 'M6 6l12 12' }
  ],
  check: [
    { kind: 'path', d: 'M20 6L9 17l-5-5' }
  ],
  checkCircle: [
    { kind: 'path', d: 'M22 11.08V12a10 10 0 1 1-5.93-9.14' },
    { kind: 'path', d: 'M22 4L12 14.01l-3-3' }
  ],
  xmark: [
    { kind: 'path', d: 'M18 6L6 18' }, { kind: 'path', d: 'M6 6l12 12' }
  ],
  arrowRight: [
    { kind: 'path', d: 'M9 18l6-6-6-6' }
  ],
  chevronRight: [
    { kind: 'path', d: 'M9 18l6-6-6-6' }
  ],
  phone: [
    { kind: 'path', d: 'M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z' }
  ],
  chat: [
    { kind: 'path', d: 'M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z' }
  ],
  link: [
    { kind: 'path', d: 'M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71' },
    { kind: 'path', d: 'M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71' }
  ],
  camera: [
    { kind: 'path', d: 'M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z' },
    { kind: 'circle', cx: 12, cy: 13, r: 4 }
  ],
  download: [
    { kind: 'path', d: 'M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4' },
    { kind: 'path', d: 'M7 10l5 5 5-5' }, { kind: 'path', d: 'M12 15V3' }
  ],
  location: [
    { kind: 'path', d: 'M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z' },
    { kind: 'circle', cx: 12, cy: 10, r: 3 }
  ],
  edit: [
    { kind: 'path', d: 'M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7' },
    { kind: 'path', d: 'M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z' }
  ],
  folder: [
    { kind: 'path', d: 'M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z' }
  ],
  device: [
    { kind: 'rect', x: 5, y: 2, w: 14, h: 20, rx: 2 }, { kind: 'path', d: 'M12 18h.01' }
  ],
  puzzle: [
    { kind: 'path', d: 'M19.439 7.85c-.049.322.059.648.289.878l1.568 1.568c.47.47.706 1.087.706 1.704s-.235 1.233-.706 1.704l-1.611 1.611a.98.98 0 0 1-.837.276c-.47-.07-.802-.48-.968-.925a2.501 2.501 0 1 0-3.214 3.214c.446.166.855.497.925.968a.979.979 0 0 1-.276.837l-1.61 1.61a2.404 2.404 0 0 1-1.705.707 2.402 2.402 0 0 1-1.704-.706l-1.568-1.568a1.026 1.026 0 0 0-.877-.29c-.493.074-.84.504-1.02.968a2.5 2.5 0 1 1-3.237-3.237c.464-.18.894-.527.967-1.02a1.026 1.026 0 0 0-.289-.877l-1.568-1.568A2.402 2.402 0 0 1 1.998 12c0-.617.236-1.234.706-1.704L4.23 8.77c.24-.24.581-.353.917-.303.515.077.877.528 1.073 1.01a2.5 2.5 0 1 0 3.259-3.259c-.482-.196-.933-.558-1.01-1.073-.05-.336.062-.676.303-.917l1.525-1.525A2.402 2.402 0 0 1 12 1.998c.617 0 1.234.236 1.704.706l1.568 1.568c.23.23.556.338.877.29.493-.074.84-.504 1.02-.968a2.5 2.5 0 1 1 3.237 3.237c-.464.18-.894.527-.967 1.02Z' }
  ],
  calendar: [
    { kind: 'rect', x: 3, y: 4, w: 18, h: 18, rx: 2 },
    { kind: 'path', d: 'M16 2v4' }, { kind: 'path', d: 'M8 2v4' }, { kind: 'path', d: 'M3 10h18' }
  ],
  clock: [
    { kind: 'circle', cx: 12, cy: 12, r: 10 }, { kind: 'path', d: 'M12 6v6l4 2' }
  ],
  send: [
    { kind: 'path', d: 'M22 2L11 13' }, { kind: 'path', d: 'M22 2l-7 20-4-9-9-4 20-7z' }
  ],
  sun: [
    { kind: 'circle', cx: 12, cy: 12, r: 4 },
    { kind: 'path', d: 'M12 2v2' }, { kind: 'path', d: 'M12 20v2' },
    { kind: 'path', d: 'M4.93 4.93l1.41 1.41' }, { kind: 'path', d: 'M17.66 17.66l1.41 1.41' },
    { kind: 'path', d: 'M2 12h2' }, { kind: 'path', d: 'M20 12h2' },
    { kind: 'path', d: 'M6.34 17.66l-1.41 1.41' }, { kind: 'path', d: 'M19.07 4.93l-1.41 1.41' }
  ],
  moon: [
    { kind: 'path', d: 'M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z' }
  ],
  star: [
    { kind: 'path', d: 'M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z' }
  ],
  graduate: [
    { kind: 'path', d: 'M22 10L12 5 2 10l10 5 10-5z' },
    { kind: 'path', d: 'M6 12v5c0 1.7 3 3 6 3s6-1.3 6-3v-5' }
  ],
  sparkles: [
    { kind: 'path', d: 'M12 3l1.9 5.8a2 2 0 0 0 1.3 1.3L21 12l-5.8 1.9a2 2 0 0 0-1.3 1.3L12 21l-1.9-5.8a2 2 0 0 0-1.3-1.3L3 12l5.8-1.9a2 2 0 0 0 1.3-1.3L12 3z' },
    { kind: 'path', d: 'M5 3v4' }, { kind: 'path', d: 'M3 5h4' },
    { kind: 'path', d: 'M19 17v4' }, { kind: 'path', d: 'M17 19h4' }
  ],
  box: [
    { kind: 'path', d: 'M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z' },
    { kind: 'path', d: 'M3.27 6.96L12 12.01l8.73-5.05' }, { kind: 'path', d: 'M12 22.08V12' }
  ],
  building: [
    { kind: 'rect', x: 4, y: 2, w: 16, h: 20, rx: 2 },
    { kind: 'path', d: 'M9 22v-4h6v4' },
    { kind: 'path', d: 'M8 6h.01' }, { kind: 'path', d: 'M16 6h.01' }, { kind: 'path', d: 'M12 6h.01' },
    { kind: 'path', d: 'M12 10h.01' }, { kind: 'path', d: 'M12 14h.01' }, { kind: 'path', d: 'M16 10h.01' },
    { kind: 'path', d: 'M16 14h.01' }, { kind: 'path', d: 'M8 10h.01' }, { kind: 'path', d: 'M8 14h.01' }
  ],
  refresh: [
    { kind: 'path', d: 'M23 4v6h-6' }, { kind: 'path', d: 'M1 20v-6h6' },
    { kind: 'path', d: 'M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15' }
  ],
  users: [
    { kind: 'path', d: 'M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2' },
    { kind: 'circle', cx: 9, cy: 7, r: 4 },
    { kind: 'path', d: 'M23 21v-2a4 4 0 0 0-3-3.87' },
    { kind: 'path', d: 'M16 3.13a4 4 0 0 1 0 7.75' }
  ],
  user: [
    { kind: 'path', d: 'M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2' },
    { kind: 'circle', cx: 12, cy: 7, r: 4 }
  ],
  home: [
    { kind: 'path', d: 'M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z' },
    { kind: 'path', d: 'M9 22V12h6v10' }
  ],
  grid: [
    { kind: 'rect', x: 3, y: 3, w: 7, h: 7, rx: 1 },
    { kind: 'rect', x: 14, y: 3, w: 7, h: 7, rx: 1 },
    { kind: 'rect', x: 3, y: 14, w: 7, h: 7, rx: 1 },
    { kind: 'rect', x: 14, y: 14, w: 7, h: 7, rx: 1 }
  ],
  dashboard: [
    { kind: 'rect', x: 3, y: 3, w: 7, h: 9, rx: 1 },
    { kind: 'rect', x: 14, y: 3, w: 7, h: 5, rx: 1 },
    { kind: 'rect', x: 14, y: 12, w: 7, h: 9, rx: 1 },
    { kind: 'rect', x: 3, y: 16, w: 7, h: 5, rx: 1 }
  ],
  list: [
    { kind: 'path', d: 'M8 6h13' }, { kind: 'path', d: 'M8 12h13' }, { kind: 'path', d: 'M8 18h13' },
    { kind: 'path', d: 'M3 6h.01' }, { kind: 'path', d: 'M3 12h.01' }, { kind: 'path', d: 'M3 18h.01' }
  ],
  layers: [
    { kind: 'path', d: 'M12 2L2 7l10 5 10-5-10-5z' },
    { kind: 'path', d: 'M2 17l10 5 10-5' }, { kind: 'path', d: 'M2 12l10 5 10-5' }
  ],
  refreshCw: [
    { kind: 'path', d: 'M23 4v6h-6' }, { kind: 'path', d: 'M1 20v-6h6' },
    { kind: 'path', d: 'M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15' }
  ],
  info: [
    { kind: 'circle', cx: 12, cy: 12, r: 10 }, { kind: 'path', d: 'M12 16v-4' }, { kind: 'path', d: 'M12 8h.01' }
  ],
  flame: [
    { kind: 'path', d: 'M8.5 14.5A2.5 2.5 0 0 0 11 12c0-1.38-.5-2-1-3-1.072-2.143-.224-4.054 2-6 .5 2.5 2 4.9 4 6.5 2 1.6 3 3.5 3 5.5a7 7 0 1 1-14 0c0-1.153.433-2.294 1-3a2.5 2.5 0 0 0 2.5 2.5z' }
  ],
  wallet: [
    { kind: 'path', d: 'M21 12V7H5a2 2 0 0 1 0-4h14v4' },
    { kind: 'path', d: 'M3 5v14a2 2 0 0 0 2 2h16v-5' },
    { kind: 'path', d: 'M18 12a2 2 0 0 0 0 4h4v-4Z' }
  ],
  eye: [
    { kind: 'path', d: 'M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z' },
    { kind: 'circle', cx: 12, cy: 12, r: 3 }
  ],
  settings: [
    { kind: 'path', d: 'M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z' },
    { kind: 'circle', cx: 12, cy: 12, r: 3 }
  ],
  heart: [
    { kind: 'path', d: 'M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z' }
  ],
  award: [
    { kind: 'circle', cx: 12, cy: 8, r: 6 },
    { kind: 'path', d: 'M15.477 12.89L17 22l-5-3-5 3 1.523-9.11' }
  ],
  alertCircle: [
    { kind: 'circle', cx: 12, cy: 12, r: 10 }, { kind: 'path', d: 'M12 8v4' }, { kind: 'path', d: 'M12 16h.01' }
  ]
}

export default {
  name: 'MIcon',
  props: {
    name: { type: String, default: '' },
    size: { type: [Number, String], default: 22 },
    color: { type: String, default: '' },
    weight: { type: [Number, String], default: 1.8 },
    g1: { type: String, default: '' },
    g2: { type: String, default: '' }
  },
  computed: {
    gid() {
      return 'mg_' + (this._uid || Math.random().toString(36).slice(2, 8))
    },
    paths() {
      return ICONS[this.name] || []
    },
    strokeVal() {
      if (this.g1 && this.g2) return 'url(#' + this.gid + ')'
      return this.color || 'currentColor'
    },
    svgStyle() {
      const s = {}
      if (this.color) s.color = this.color
      return s
    },
    viewBox() {
      return '0 0 24 24'
    },
    // #ifdef MP-WEIXIN
    iconSrc() {
      const shapes = (this.paths || []).map(p => {
        if (p.kind === 'path') return '<path d="' + p.d + '"/>'
        if (p.kind === 'circle') return '<circle cx="' + p.cx + '" cy="' + p.cy + '" r="' + p.r + '"/>'
        if (p.kind === 'rect') return '<rect x="' + p.x + '" y="' + p.y + '" width="' + p.w + '" height="' + p.h + '" rx="' + (p.rx || 0) + '" ry="' + (p.ry || 0) + '"/>'
        if (p.kind === 'line') return '<line x1="' + p.x1 + '" y1="' + p.y1 + '" x2="' + p.x2 + '" y2="' + p.y2 + '"/>'
        if (p.kind === 'polyline') return '<polyline points="' + p.points + '"/>'
        return ''
      }).join('')
      let defs = ''
      let stroke = this.color || '#1a1a1a'
      if (this.g1 && this.g2) {
        const g = this.gid
        defs = '<defs><linearGradient id="' + g + '" x1="0%" y1="0%" x2="100%" y2="100%"><stop offset="0%" stop-color="' + this.g1 + '"/><stop offset="100%" stop-color="' + this.g2 + '"/></linearGradient></defs>'
        stroke = 'url(#' + g + ')'
      }
      const svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="' + stroke + '" stroke-width="' + this.weight + '" stroke-linecap="round" stroke-linejoin="round">' + defs + shapes + '</svg>'
      return 'data:image/svg+xml;base64,' + this._b64(svg)
    },
    // #endif
  },
  methods: {
    // #ifdef MP-WEIXIN
    _b64(str) {
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
      let out = ''
      for (let i = 0; i < str.length; i += 3) {
        const c1 = str.charCodeAt(i)
        const c2 = i + 1 < str.length ? str.charCodeAt(i + 1) : NaN
        const c3 = i + 2 < str.length ? str.charCodeAt(i + 2) : NaN
        const e1 = c1 >> 2
        const e2 = ((c1 & 3) << 4) | ((isNaN(c2) ? 0 : c2) >> 4)
        const e3 = isNaN(c2) ? 64 : (((c2 & 15) << 2) | ((isNaN(c3) ? 0 : c3) >> 6))
        const e4 = isNaN(c3) ? 64 : (c3 & 63)
        out += chars.charAt(e1) + chars.charAt(e2) + (e3 === 64 ? '=' : chars.charAt(e3)) + (e4 === 64 ? '=' : chars.charAt(e4))
      }
      return out
    }
    // #endif
  }
}
</script>

<style scoped>
.m-icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  line-height: 0;
}
.m-icon svg {
  display: block;
}
.m-icon image {
  display: block;
}
</style>
