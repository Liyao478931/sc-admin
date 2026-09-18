<template>
  <div class="crmeb-diy-editor">
    <!-- 顶部工具栏 -->
    <div class="editor-toolbar">
      <el-button size="small" @click="goBack"><i class="el-icon-arrow-left"></i> 返回</el-button>
      <el-input v-model="pageName" size="small" placeholder="页面名称" style="width:180px;margin-left:8px" maxlength="15" />
      <el-tag :type="status === 1 ? 'success' : 'info'" size="small" style="margin-left:8px">{{ status === 1 ? '已启用' : '未启用' }}</el-tag>
      <el-button size="small" style="margin-left:8px" @click="accessDialogVisible = true"><i class="el-icon-lock"></i> 权限设置</el-button>
      <div style="flex:1"></div>
      <el-button size="small" type="primary" :loading="saving" @click="handleSave">保存</el-button>
      <el-button size="small" :type="previewMode ? 'warning' : 'primary'" @click="togglePreview">{{ previewMode ? '返回编辑' : '预览' }}</el-button>
    </div>

    <div class="editor-body">
      <!-- 左侧：组件库 -->
      <div class="component-panel">
        <div class="panel-header">
          <span class="panel-title">📦 组件库</span>
          <span class="panel-count">{{ componentDefs.length }}个组件</span>
        </div>
        <div class="panel-scroll">
          <div class="component-group">
            <div class="group-title">通用组件</div>
            <div class="group-items">
              <div class="component-item" v-for="comp in componentDefs" :key="comp.name" @click="addComponent(comp)">
                <i :class="comp.icon" style="font-size:18px;width:24px;color:#409EFF"></i>
                <span class="comp-name">{{ comp.cname }}</span>
              </div>
            </div>
          </div>
          <!-- 页面组件列表（选中/删除/排序） -->
          <div class="component-group">
            <div class="group-title">页面组件（{{ componentList.length }}）</div>
            <div class="group-items">
              <draggable v-model="componentList" group="components" @end="saveHistory">
                <div v-for="(item, index) in componentList" :key="item.id"
                  class="component-item page-comp-item"
                  :class="{ 'page-comp-active': activeIndex === index }"
                  @click="selectComponent(index)">
                  <i :class="itemIcon(item.name)" style="font-size:16px;width:22px;color:#409EFF"></i>
                  <span class="comp-name">{{ item.cname }}</span>
                  <i class="el-icon-delete page-comp-del" @click.stop="removeComponent(index)"></i>
                </div>
              </draggable>
              <div v-if="componentList.length === 0" style="font-size:12px;color:#C0C4CC;padding:8px 12px">暂无组件，点击上方添加</div>
            </div>
          </div>
        </div>
      </div>

      <!-- 中间：画布 -->
      <div class="canvas-wrap">
        <!-- iframe 实时预览视图（previewMode 时显示） -->
        <div v-if="previewMode" class="canvas-preview">
          <div class="preview-toolbar">
            <el-tag size="small" type="success">实时预览（与小程序/H5一致）</el-tag>
            <el-button size="small" @click="previewMode = false"><i class="el-icon-back"></i> 返回编辑</el-button>
            <el-button size="small" icon="el-icon-refresh" @click="refreshPreview">刷新</el-button>
          </div>
          <iframe :src="iframeSrc" class="preview-frame" frameborder="0"></iframe>
        </div>
        <!-- 可编辑画布（默认显示，点击组件配置） -->
        <div v-else class="canvas">
          <div class="canvas-scroll">
            <draggable v-model="componentList" group="components" class="canvas-list" @end="saveHistory">
              <div v-for="(item, index) in componentList" :key="item.id"
                class="canvas-item"
                :class="{ active: activeIndex === index }"
                @click.stop="selectComponent(index)">
                <div class="canvas-item-toolbar">
                  <span class="item-name">{{ item.cname }}</span>
                  <i class="el-icon-delete" @click.stop="removeComponent(index)"></i>
                </div>
                <!-- 组件渲染（对齐移动端渲染器 diy/index.vue） -->
                <div class="item-preview" :style="pvStyle(item)">
                  <template v-if="item.name === 'banner'">
                    <div v-if="item.swiperConfig && item.swiperConfig.list" class="pv-banner">
                      <div v-for="(img,i) in item.swiperConfig.list.slice(0,1)" :key="i" class="pv-banner-imgwrap"
                        :style="{ margin: '0 '+(item.imgConfig?.val||0)+'px', borderRadius:(item.filletImg?.val||0)+'px', boxShadow: shadowStyle(item.imgShadowConfig) }">
                        <img :src="toFullUrl(img.img)" style="width:100%;height:160px;object-fit:cover;border-radius:8px" />
                      </div>
                      <div v-if="item.swiperConfig.list.length > 1" class="pv-banner-dots" :style="{justifyContent:item.docPosition?.tabVal===0?'flex-start':item.docPosition?.tabVal===2?'flex-end':'center'}">
                        <span v-for="(img,i) in item.swiperConfig.list" :key="i" class="pv-banner-dot"
                          :style="{background:i===0?(item.dotColor?.color?.[0]?.item||'#E93323'):(item.dotBgColor?.color?.[0]?.item||'#DDDDDD')}"></span>
                      </div>
                    </div>
                  </template>
                  <template v-else-if="item.name === 'home_menu'">
                    <div class="pv-menu" :style="{gridTemplateColumns:'repeat('+(item.menuConfig?.columns||4)+',1fr)',borderRadius:(item.filletImg?.val||0)+'px'}">
                      <div v-for="(m,i) in (item.menuConfig?.list||[]).slice(0,8)" :key="i" class="pv-menu-item">
                        <div :style="{boxShadow:shadowStyle(item.imgShadowConfig)}">
                          <img v-if="m.img" :src="toFullUrl(m.img)" style="width:36px;height:36px;object-fit:contain" />
                          <i v-else class="el-icon-menu" style="font-size:26px;color:#409EFF"></i>
                        </div>
                        <span :style="{color:item.textColor?.color?.[0]?.item||'#333'}">{{ m.title }}</span>
                      </div>
                    </div>
                  </template>
                  <template v-else-if="item.name === 'home_title'">
                    <div class="pv-title-row" :style="{justifyContent:item.titleAlign?.tabVal===0?'flex-start':item.titleAlign?.tabVal===2?'flex-end':'center'}">
                      <span class="pv-title" :style="{fontSize:(item.titleSize?.val||18)+'px',color:item.titleColor?.color?.[0]?.item||'#282828'}">{{ item.titleConfig?.val || '标题' }}</span>
                      <span v-if="item.buttonConfig?.tabVal===0" class="pv-title-btn" :style="{color:item.buttonColor?.color?.[0]?.item||'#4F46E5'}" @click="navigatePreview(item.linkConfig?.val)">{{ item.buttonText?.val || '更多' }}</span>
                    </div>
                  </template>
                  <template v-else-if="item.name === 'richText'">
                    <div :style="{paddingLeft:(item.lrConfig?.val||0)+'px',paddingRight:(item.lrConfig?.val||0)+'px',paddingTop:(item.udConfig?.val||0)+'px',paddingBottom:(item.udConfig?.val||0)+'px'}">
                      <div class="pv-rich" v-html="item.contentConfig?.val || ''"></div>
                    </div>
                  </template>
                  <template v-else-if="item.name === 'picture_cube'">
                    <div class="pv-cube" :style="{gap:(item.imgConfig?.val||6)+'px'}">
                      <img v-for="(img,i) in (item.cubeConfig?.list||[]).slice(0,4)" :key="i" :src="toFullUrl(img.img)"
                        :style="{width:'48%',height:'80px',objectFit:'cover',borderRadius:(item.filletImg?.val||8)+'px',boxShadow:shadowStyle(item.imgShadowConfig)}" />
                    </div>
                  </template>
                  <template v-else-if="item.name === 'search_box'">
                    <div class="pv-search">
                      <img v-if="item.logoConfig?.url" :src="toFullUrl(item.logoConfig.url)" style="width:24px;height:24px;object-fit:contain" />
                      <input disabled :placeholder="item.searchTipConfig?.place || '请输入搜索内容'" />
                      <span v-if="item.titleSearch?.tabVal===1" class="pv-search-btn">{{ item.btnTextConfig?.val || '搜索' }}</span>
                    </div>
                  </template>
                  <template v-else-if="item.name === 'news_roll'">
                    <div class="pv-news">
                      <span v-if="item.titleStyle?.tabVal===0" class="pv-news-title">{{ item.titleConfig?.val || '公告' }}</span>
                      <span>📢 {{ (item.newsConfig?.list||[{val:'公告'}])[0].val }}</span>
                    </div>
                  </template>
                  <template v-else-if="item.name === 'z_auxiliary_line'">
                    <div :style="{borderTop:(item.lineHeight?.val||1)+'px '+(item.lineStyle?.tabVal===1?'dashed':item.lineStyle?.tabVal===2?'dotted':'solid')+' '+(item.lineColor?.color?.[0]?.item||'#E8ECF1'),margin:'0 '+(item.lrEdge?.val||12)+'px'}"></div>
                  </template>
                  <template v-else-if="item.name === 'z_auxiliary_box'">
                    <div :style="{height:(item.heightConfig?.val||20)+'px',background:item.bgColor?.color?.[0]?.item||'#fff',margin:'0 '+(item.lrEdge?.val||0)+'px'}"></div>
                  </template>
                  <template v-else-if="item.name === 'video'">
                    <div class="pv-video">
                      <video v-if="item.videoConfig?.url" :src="item.videoConfig.url" controls style="width:100%;max-height:200px;border-radius:8px"></video>
                      <div v-else class="pv-unknown">📹 视频组件（请在右侧配置视频地址）</div>
                    </div>
                  </template>
                  <template v-else-if="item.name === 'hotspot'">
                    <div class="pv-hotspot" :style="{position:'relative'}">
                      <img :src="toFullUrl(item.hotspotConfig?.img)" style="width:100%;max-height:200px;object-fit:cover;border-radius:8px" />
                      <div v-for="(h,i) in (item.hotspotConfig?.list||[])" :key="i"
                        :style="{position:'absolute',left:h.x+'%',top:h.y+'%',width:(h.w||10)+'%',height:(h.h||10)+'%',border:'1px dashed #409EFF',background:'rgba(64,158,255,0.15)'}"></div>
                    </div>
                  </template>
                  <template v-else-if="item.name === 'customerService'">
                    <div class="pv-service" :style="{justifyContent:(item.locationConfig?.tabVal===0?'flex-start':'flex-end')}">
                      <div class="pv-service-btn" :style="{background:item.bgColor?.color?.[0]?.item||'#4F46E5'}">
                        <img v-if="item.logoConfig?.url" :src="toFullUrl(item.logoConfig.url)" style="width:22px;height:22px;object-fit:contain;border-radius:50%" />
                        <i v-else class="el-icon-service" style="font-size:20px;color:#fff"></i>
                        <span v-if="item.buttonText?.val" style="color:#fff;font-size:12px">{{ item.buttonText.val }}</span>
                      </div>
                    </div>
                  </template>
                  <template v-else-if="item.name === 'wechat_attention'">
                    <div class="pv-wechat">
                      <div class="pv-wechat-left">
                        <div class="pv-wechat-avatar">
                          <img v-if="item.imgConfig?.url" :src="toFullUrl(item.imgConfig.url)" style="width:36px;height:36px;border-radius:50%;object-fit:cover" />
                          <i v-else class="el-icon-message" style="font-size:20px;color:#909399"></i>
                        </div>
                        <span style="font-size:13px;color:#333">{{ item.titleConfig?.value || '公众号标题' }}</span>
                      </div>
                      <div class="pv-wechat-btn" :style="{color:item.btnTextColor?.color?.[0]?.item||'#E93323'}">关注</div>
                    </div>
                  </template>
                  <template v-else-if="item.name === 'tabNav'">
                    <div class="pv-tabnav" :style="{background:item.bgColor?.color?.[0]?.item||'#fff'}">
                      <span v-for="(t,i) in (item.tabListConfig?.list||[])" :key="i" class="pv-tabnav-item"
                        :class="{active:i===0}" :style="i===0?{color:item.textColor?.color?.[0]?.item||'#E93323',borderBottom:'2px solid '+(item.decorateColor?.color?.[0]?.item||'#E93323')}:{}">{{ t.text?.val || '选项卡' }}</span>
                    </div>
                  </template>
                  <template v-else-if="item.name === 'pageFoot'">
                    <!-- 旧数据兼容：底部导航已由系统统一配置，此处仅作提示 -->
                    <div style="padding:12px;text-align:center;color:#C0C4CC;font-size:12px">底部导航（由系统统一配置，请在「底部导航配置」中管理）</div>
                  </template>
                  <template v-else-if="['device-list','repair-list','hazard-list','inventory-alert'].includes(item.name)">
                    <div class="pv-biz">
                      <div class="pv-biz-head">
                        <span class="pv-biz-title">{{ item.titleConfig?.val || item.cname }}</span>
                        <span class="pv-biz-badge">业务组件</span>
                      </div>
                      <div class="pv-biz-body">
                        <div v-for="i in Math.min(3, item.limitConfig?.val || 3)" :key="i" class="pv-biz-row">
                          <span class="pv-biz-line" style="width:60%"></span>
                          <span class="pv-biz-line" style="width:25%"></span>
                        </div>
                      </div>
                      <div class="pv-biz-note">移动端加载业务数据（{{ item.cname }}）</div>
                    </div>
                  </template>
                  <template v-else>
                    <div class="pv-unknown">🧩 {{ item.cname }}</div>
                  </template>
                </div>
              </div>
            </draggable>
            <div v-if="componentList.length === 0" class="empty-state">
              <div class="empty-icon">📐</div>
              <div class="empty-text">从左侧点击或拖拽组件到此处</div>
            </div>
          </div>
          <!-- 画布底部固定底部导航（实时显示系统配置，对齐移动端 CustomTabBar） -->
          <div v-if="liveTabs.length" class="canvas-footbar">
            <div class="canvas-footbar-item" v-for="(t,i) in liveTabs" :key="i"
              :style="i===0?{color:'#C44F4F'}:{color:'#A3A3A3'}">
              <img v-if="footIcon(t).type === 'img'" :src="toFullUrl(footIcon(t).url)" style="width:20px;height:20px;object-fit:contain" />
              <span v-else style="font-size:18px;line-height:20px">{{ footIcon(t).text }}</span>
              <span style="font-size:10px">{{ t.title || 'Tab' }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- 右侧：属性配置 -->
      <div class="property-panel">
        <div v-if="!selectedComponent" class="empty-property">
          <div class="empty-icon">👆</div>
          <div class="empty-text">点击画布组件进行配置</div>
        </div>
        <div v-else>
          <div class="property-header">
            <span class="section-title">{{ selectedComponent.cname }}</span>
          </div>
          <!-- 组件专属配置（对齐 CRMEB：专属分组在前） -->
          <component :is="'prop-' + selectedComponent.name" v-if="hasPropComponent(selectedComponent.name)" :item="selectedComponent" />
          <div v-else class="prop-group">
            <div class="prop-group-title">组件配置</div>
            <el-form size="small" label-width="80px">
              <el-form-item v-for="(v,k) in selectedComponent" :key="k" v-if="isEditableProp(k)">
                <template v-if="isColorProp(v)">
                  <span slot="label">{{ v.title || k }}</span>
                  <el-color-picker v-model="v.color[0].item" size="small" />
                </template>
                <template v-else-if="isSliderProp(v)">
                  <span slot="label">{{ v.title || k }}</span>
                  <el-slider v-model="v.val" :min="v.min||0" :max="v.max||100" />
                </template>
                <template v-else-if="isTextProp(v)">
                  <span slot="label">{{ v.title || k }}</span>
                  <el-input v-model="v.val" size="small" />
                </template>
              </el-form-item>
            </el-form>
          </div>
          <!-- 通用属性：卡片样式（对齐 CRMEB titleCurrency 分组，放最后） -->
          <div class="prop-group">
            <div class="prop-group-title">卡片样式</div>
            <el-form size="small" label-width="80px">
              <el-form-item label="上边距">
                <el-input-number v-model="selectedComponent.topConfig.val" :min="0" :max="100" controls-position="right" style="width:100%" />
              </el-form-item>
              <el-form-item label="下边距">
                <el-input-number v-model="selectedComponent.bottomConfig.val" :min="0" :max="100" controls-position="right" style="width:100%" />
              </el-form-item>
              <el-form-item label="左右边距">
                <el-input-number v-model="selectedComponent.prConfig.val" :min="0" :max="100" controls-position="right" style="width:100%" />
              </el-form-item>
              <el-form-item label="页面上间距">
                <el-input-number v-model="selectedComponent.mbConfig.val" :min="0" :max="100" controls-position="right" style="width:100%" />
              </el-form-item>
              <el-form-item label="组件上浮">
                <el-input-number v-model="selectedComponent.offsetYConfig.val" :min="0" :max="100" controls-position="right" style="width:100%" />
              </el-form-item>
              <el-form-item label="背景颜色">
                <el-color-picker v-model="selectedComponent.bgColor.color[0].item" size="small" />
              </el-form-item>
              <el-form-item label="圆角">
                <el-slider v-model="selectedComponent.fillet.val" :min="0" :max="40" />
              </el-form-item>
              <el-form-item label="阴影">
                <div style="display:flex;gap:6px;align-items:center">
                  <el-switch v-model="selectedComponent.shadowConfig.visible" :active-value="1" :inactive-value="0" />
                  <span style="font-size:12px;color:#909399">开启</span>
                  <el-color-picker v-model="selectedComponent.shadowConfig.color" size="mini" />
                </div>
                <el-slider v-model="selectedComponent.shadowConfig.blur" :min="0" :max="30" show-input />
              </el-form-item>
            </el-form>
          </div>
        </div>
      </div>
    </div>

    <!-- 访问权限设置（B方案） -->
    <el-dialog title="访问权限设置" :visible.sync="accessDialogVisible" width="480px" append-to-body>
      <el-form label-width="90px" size="small">
        <el-form-item label="访问权限">
          <el-radio-group v-model="accessType" size="small">
            <el-radio-button label="public">公开访问</el-radio-button>
            <el-radio-button label="login">仅登录用户</el-radio-button>
            <el-radio-button label="role">指定角色</el-radio-button>
            <el-radio-button label="user">指定用户</el-radio-button>
          </el-radio-group>
        </el-form-item>
        <el-form-item v-if="accessType === 'role'" label="选择角色">
          <el-select v-model="accessRule" multiple filterable clearable placeholder="请选择角色（可多选）" style="width:100%">
            <el-option v-for="r in rolesOptions" :key="r.value" :label="r.label" :value="r.value"></el-option>
          </el-select>
        </el-form-item>
        <el-form-item v-if="accessType === 'user'" label="选择用户">
          <el-select v-model="accessRule" multiple filterable clearable placeholder="请选择用户（可多选）" style="width:100%">
            <el-option v-for="u in usersOptions" :key="u.value" :label="u.label" :value="u.value"></el-option>
          </el-select>
        </el-form-item>
        <el-form-item label="权限预览">
          <el-tag :type="accessType === 'public' ? 'info' : 'warning'" size="small">{{ accessPreviewText }}</el-tag>
        </el-form-item>
      </el-form>
      <span slot="footer">
        <el-button size="small" @click="accessDialogVisible = false">关闭</el-button>
        <el-button size="small" type="primary" @click="accessDialogVisible = false">确定</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import draggable from 'vuedraggable'
import { C_COMPONENT_DEFS, genTs } from './crmeb-diy-config'
import { diyDetail, diySave, diyStatus, getRoleOptions, getUserOptions } from '@/api/diy'
import request from '@/api/request'
import DiyUploadImg from './DiyUploadImg.vue'
import DiyLinkPicker from './DiyLinkPicker.vue'

// 组件专属属性面板（按需注册）
const propComponents = {
  'banner': {
    template: `
      <div>
      <div class="prop-group">
        <div class="prop-group-title">展示设置</div>
        <el-form size="small" label-width="80px">
          <el-form-item label="自动播放">
            <el-switch v-model="item.setUp.tabVal" :active-value="1" :inactive-value="0" />
          </el-form-item>
          <el-form-item label="选择风格">
            <el-radio-group v-model="item.styleConfig.tabVal" size="small">
              <el-radio-button v-for="(s,i) in item.styleConfig.tabList" :key="i" :label="i">{{ s.name }}</el-radio-button>
            </el-radio-group>
          </el-form-item>
        </el-form>
      </div>
      <div class="prop-group">
        <div class="prop-group-title">内容设置</div>
        <el-form size="small" label-width="80px">
          <el-form-item label="图片列表">
            <div v-for="(img,i) in item.swiperConfig.list" :key="i" class="prop-item">
              <DiyLinkPicker v-model="img.link" />
              <div style="display:flex;gap:8px;align-items:center;margin-top:4px">
                <DiyUploadImg v-model="img.img" />
                <div style="flex:1">
                  <el-input v-model="img.img" size="mini" placeholder="图片URL" />
                  <el-button size="mini" type="text" icon="el-icon-delete" @click="item.swiperConfig.list.splice(i,1)" style="margin-top:4px">删除</el-button>
                </div>
              </div>
            </div>
            <el-button size="mini" style="width:100%" @click="item.swiperConfig.list.push({img:'',link:''})">+ 添加图片</el-button>
          </el-form-item>
        </el-form>
      </div>
      <div class="prop-group">
        <div class="prop-group-title">指示器设置</div>
        <el-form size="small" label-width="80px">
          <el-form-item label="指示器样式">
            <el-radio-group v-model="item.docConfig.tabVal" size="small">
              <el-radio-button v-for="(s,i) in item.docConfig.tabList" :key="i" :label="i">{{ s.name }}</el-radio-button>
            </el-radio-group>
          </el-form-item>
          <el-form-item label="指示器位置">
            <el-radio-group v-model="item.docPosition.tabVal" size="small">
              <el-radio-button v-for="(s,i) in item.docPosition.tabList" :key="i" :label="i">{{ s.name }}</el-radio-button>
            </el-radio-group>
          </el-form-item>
          <el-form-item label="色调">
            <el-radio-group v-model="item.toneConfig.tabVal" size="small">
              <el-radio-button :label="0">跟随主题</el-radio-button>
              <el-radio-button :label="1">自定义</el-radio-button>
            </el-radio-group>
          </el-form-item>
          <el-form-item v-if="item.toneConfig.tabVal===1" label="指示器颜色">
            <div style="display:flex;gap:8px;align-items:center">
              <span style="font-size:12px;color:#909399">选中</span>
              <el-color-picker v-model="item.dotColor.color[0].item" size="small" />
              <span style="font-size:12px;color:#909399">常规</span>
              <el-color-picker v-model="item.dotBgColor.color[0].item" size="small" />
            </div>
          </el-form-item>
        </el-form>
      </div>
      <div class="prop-group">
        <div class="prop-group-title">图片设置</div>
        <el-form size="small" label-width="80px">
          <el-form-item label="图片圆角">
            <el-slider v-model="item.filletImg.val" :min="0" :max="40" />
          </el-form-item>
          <el-form-item label="图片间距">
            <el-slider v-model="item.imgConfig.val" :min="0" :max="20" />
          </el-form-item>
          <el-form-item label="图片阴影">
            <div style="display:flex;gap:6px;align-items:center">
              <el-switch v-model="item.imgShadowConfig.visible" :active-value="1" :inactive-value="0" />
              <span style="font-size:12px;color:#909399">开启</span>
              <el-color-picker v-model="item.imgShadowConfig.color" size="mini" />
            </div>
          </el-form-item>
        </el-form>
      </div>
      </div>
    `,
    props: { item: Object }
  },
  'home_menu': {
    template: `
      <div>
      <div class="prop-group">
        <div class="prop-group-title">展示设置</div>
        <el-form size="small" label-width="80px">
          <el-form-item label="导航样式">
            <el-radio-group v-model="item.menuStyleConfig.tabVal" size="small">
              <el-radio-button v-for="(s,i) in item.menuStyleConfig.tabList" :key="i" :label="i">{{ s.name }}</el-radio-button>
            </el-radio-group>
          </el-form-item>
          <el-form-item label="单行显示">
            <el-radio-group v-model="item.number.tabVal" size="small">
              <el-radio-button :label="0">3个</el-radio-button>
              <el-radio-button :label="1">4个</el-radio-button>
              <el-radio-button :label="2">5个</el-radio-button>
            </el-radio-group>
          </el-form-item>
          <el-form-item label="展示样式">
            <el-radio-group v-model="item.showConfig.tabVal" size="small">
              <el-radio-button :label="0">固定显示</el-radio-button>
              <el-radio-button :label="1">滑动显示</el-radio-button>
            </el-radio-group>
          </el-form-item>
          <el-form-item label="显示行数">
            <el-radio-group v-model="item.rowsNum.tabVal" size="small">
              <el-radio-button :label="0">1行</el-radio-button>
              <el-radio-button :label="1">2行</el-radio-button>
            </el-radio-group>
          </el-form-item>
        </el-form>
      </div>
      <div class="prop-group">
        <div class="prop-group-title">内容设置</div>
        <el-form size="small" label-width="80px">
          <el-form-item label="列数">
            <el-radio-group v-model="item.menuConfig.columns" size="small">
              <el-radio-button :label="3">3</el-radio-button>
              <el-radio-button :label="4">4</el-radio-button>
              <el-radio-button :label="5">5</el-radio-button>
            </el-radio-group>
          </el-form-item>
          <el-form-item label="菜单列表">
            <div v-for="(m,i) in item.menuConfig.list" :key="i" class="prop-item">
              <div style="display:flex;gap:4px;align-items:center">
                <DiyUploadImg v-model="m.img" upload-type="image" />
                <div style="flex:1">
                  <el-input v-model="m.title" size="mini" placeholder="名称" />
                  <el-button size="mini" type="text" icon="el-icon-delete" @click="item.menuConfig.list.splice(i,1)" style="margin-top:4px">删除</el-button>
                </div>
              </div>
              <DiyLinkPicker v-model="m.link" style="margin-top:4px" />
            </div>
            <el-button size="mini" style="width:100%" @click="item.menuConfig.list.push({img:'',title:'新菜单',link:''})">+ 添加菜单</el-button>
          </el-form-item>
        </el-form>
      </div>
      <div class="prop-group">
        <div class="prop-group-title">样式设置</div>
        <el-form size="small" label-width="80px">
          <el-form-item label="文字颜色">
            <el-color-picker v-model="item.textColor.color[0].item" size="small" />
          </el-form-item>
          <el-form-item label="背景圆角">
            <el-slider v-model="item.filletImg.val" :min="0" :max="40" />
          </el-form-item>
          <el-form-item label="图标阴影">
            <div style="display:flex;gap:6px;align-items:center">
              <el-switch v-model="item.imgShadowConfig.visible" :active-value="1" :inactive-value="0" />
              <span style="font-size:12px;color:#909399">开启</span>
              <el-color-picker v-model="item.imgShadowConfig.color" size="mini" />
            </div>
          </el-form-item>
        </el-form>
      </div>
      </div>
    `,
    props: { item: Object }
  },
  'home_title': {
    template: `
      <div class="prop-group">
        <div class="prop-group-title">标题配置</div>
        <el-form size="small" label-width="80px">
          <el-form-item label="内容"><el-input v-model="item.titleConfig.val" size="small" /></el-form-item>
          <el-form-item label="大小"><el-input-number v-model="item.titleSize.val" :min="12" :max="32" controls-position="right" style="width:100%" /></el-form-item>
          <el-form-item label="颜色"><el-color-picker v-model="item.titleColor.color[0].item" size="small" /></el-form-item>
          <el-form-item label="对齐方式">
            <el-radio-group v-model="item.titleAlign.tabVal" size="small">
              <el-radio-button :label="0">左</el-radio-button>
              <el-radio-button :label="1">中</el-radio-button>
              <el-radio-button :label="2">右</el-radio-button>
            </el-radio-group>
          </el-form-item>
          <el-form-item label="右侧按钮">
            <el-radio-group v-model="item.buttonConfig.tabVal" size="small">
              <el-radio-button :label="0">显示</el-radio-button>
              <el-radio-button :label="1">不显示</el-radio-button>
            </el-radio-group>
          </el-form-item>
          <template v-if="item.buttonConfig.tabVal === 0">
            <el-form-item label="按钮文字"><el-input v-model="item.buttonText.val" size="small" /></el-form-item>
            <el-form-item label="按钮颜色"><el-color-picker v-model="item.buttonColor.color[0].item" size="small" /></el-form-item>
            <el-form-item label="跳转链接"><DiyLinkPicker v-model="item.linkConfig.val" /></el-form-item>
          </template>
        </el-form>
      </div>
    `,
    props: { item: Object }
  },
  'richText': {
    template: `
      <div class="prop-group">
        <div class="prop-group-title">富文本配置</div>
        <el-form size="small" label-width="80px">
          <el-form-item label="内容"><el-input v-model="item.contentConfig.val" type="textarea" :rows="5" /></el-form-item>
          <el-form-item label="左右内边距"><el-input-number v-model="item.lrConfig.val" :min="0" :max="50" controls-position="right" style="width:100%" /></el-form-item>
          <el-form-item label="上下内边距"><el-input-number v-model="item.udConfig.val" :min="0" :max="50" controls-position="right" style="width:100%" /></el-form-item>
        </el-form>
      </div>
    `,
    props: { item: Object }
  },
  'picture_cube': {
    template: `
      <div class="prop-group">
        <div class="prop-group-title">图片魔方配置</div>
        <el-form size="small" label-width="80px">
          <el-form-item label="选择风格">
            <el-radio-group v-model="item.styleConfig.tabVal" size="small">
              <el-radio-button v-for="(s,i) in item.styleConfig.tabList" :key="i" :label="i">{{ s.name }}</el-radio-button>
            </el-radio-group>
          </el-form-item>
          <el-form-item label="标题显示">
            <el-radio-group v-model="item.titleShow.tabVal" size="small">
              <el-radio-button :label="0">显示</el-radio-button>
              <el-radio-button :label="1">不显示</el-radio-button>
            </el-radio-group>
          </el-form-item>
          <el-form-item label="图片间距"><el-slider v-model="item.imgConfig.val" :min="0" :max="20" /></el-form-item>
          <el-form-item label="图片圆角"><el-slider v-model="item.filletImg.val" :min="0" :max="40" /></el-form-item>
          <el-form-item label="图片阴影">
            <div style="display:flex;gap:6px;align-items:center">
              <el-switch v-model="item.imgShadowConfig.visible" :active-value="1" :inactive-value="0" />
              <span style="font-size:12px;color:#909399">开启</span>
              <el-color-picker v-model="item.imgShadowConfig.color" size="mini" />
            </div>
          </el-form-item>
          <el-form-item label="图片列表">
            <div v-for="(img,i) in item.cubeConfig.list" :key="i" class="prop-item">
              <div style="display:flex;gap:8px;align-items:center">
                <DiyUploadImg v-model="img.img" />
                <div style="flex:1">
                  <el-input v-model="img.img" size="mini" placeholder="图片URL" />
                  <el-button size="mini" type="text" icon="el-icon-delete" @click="item.cubeConfig.list.splice(i,1)" style="margin-top:4px">删除</el-button>
                </div>
              </div>
              <DiyLinkPicker v-model="img.link" style="margin-top:4px" />
            </div>
            <el-button size="mini" style="width:100%" @click="item.cubeConfig.list.push({img:'',link:''})">+ 添加图片</el-button>
          </el-form-item>
        </el-form>
      </div>
    `,
    props: { item: Object }
  },
  'news_roll': {
    template: `
      <div class="prop-group">
        <div class="prop-group-title">公告配置</div>
        <el-form size="small" label-width="80px">
          <el-form-item label="选择风格">
            <el-radio-group v-model="item.styleConfig.tabVal" size="small">
              <el-radio-button :label="0">横向滚动</el-radio-button>
              <el-radio-button :label="1">纵向滚动</el-radio-button>
            </el-radio-group>
          </el-form-item>
          <el-form-item label="标题样式">
            <el-radio-group v-model="item.titleStyle.tabVal" size="small">
              <el-radio-button :label="0">显示</el-radio-button>
              <el-radio-button :label="1">不显示</el-radio-button>
            </el-radio-group>
          </el-form-item>
          <el-form-item v-if="item.titleStyle.tabVal === 0" label="标题文字"><el-input v-model="item.titleConfig.val" size="small" /></el-form-item>
          <el-form-item label="滚动速度"><el-slider v-model="item.rollConfig.val" :min="1" :max="20" /></el-form-item>
          <el-form-item label="公告列表">
            <div v-for="(n,i) in item.newsConfig.list" :key="i" class="prop-item">
              <div style="display:flex;gap:4px;align-items:center">
                <el-input v-model="n.val" size="mini" placeholder="公告内容" />
                <el-button size="mini" type="text" icon="el-icon-delete" @click="item.newsConfig.list.splice(i,1)"></el-button>
              </div>
            </div>
            <el-button size="mini" style="width:100%" @click="item.newsConfig.list.push({val:'新公告'})">+ 添加公告</el-button>
          </el-form-item>
        </el-form>
      </div>
    `,
    props: { item: Object }
  },
  'search_box': {
    template: `
      <div class="prop-group">
        <div class="prop-group-title">搜索框配置</div>
        <el-form size="small" label-width="80px">
          <el-form-item label="是否固定">
            <el-radio-group v-model="item.fixedConfig.tabVal" size="small">
              <el-radio-button :label="0">固定</el-radio-button>
              <el-radio-button :label="1">不固定</el-radio-button>
            </el-radio-group>
          </el-form-item>
          <el-form-item label="选择风格">
            <el-radio-group v-model="item.styleConfig.tabVal" size="small">
              <el-radio-button v-for="(s,i) in item.styleConfig.tabList" :key="i" :label="i">{{ s.name }}</el-radio-button>
            </el-radio-group>
          </el-form-item>
          <el-form-item label="左侧图标"><DiyUploadImg v-model="item.logoConfig.url" /></el-form-item>
          <el-form-item label="搜索提示"><el-input v-model="item.searchTipConfig.place" size="small" /></el-form-item>
          <el-form-item label="显示按钮">
            <el-radio-group v-model="item.titleSearch.tabVal" size="small">
              <el-radio-button :label="1">显示</el-radio-button>
              <el-radio-button :label="0">不显示</el-radio-button>
            </el-radio-group>
          </el-form-item>
          <el-form-item v-if="item.titleSearch.tabVal === 1" label="按钮文字"><el-input v-model="item.btnTextConfig.val" size="small" /></el-form-item>
        </el-form>
      </div>
    `,
    props: { item: Object }
  },
  'z_auxiliary_line': {
    template: `
      <div class="prop-group">
        <div class="prop-group-title">辅助线配置</div>
        <el-form size="small" label-width="80px">
          <el-form-item label="线条样式">
            <el-radio-group v-model="item.lineStyle.tabVal" size="small">
              <el-radio-button :label="0">实线</el-radio-button>
              <el-radio-button :label="1">虚线</el-radio-button>
              <el-radio-button :label="2">点线</el-radio-button>
            </el-radio-group>
          </el-form-item>
          <el-form-item label="线条颜色"><el-color-picker v-model="item.lineColor.color[0].item" size="small" /></el-form-item>
          <el-form-item label="线条粗细"><el-input-number v-model="item.lineHeight.val" :min="1" :max="10" controls-position="right" style="width:100%" /></el-form-item>
          <el-form-item label="左右间距"><el-input-number v-model="item.lrEdge.val" :min="0" :max="50" controls-position="right" style="width:100%" /></el-form-item>
        </el-form>
      </div>
    `,
    props: { item: Object }
  },
  'z_auxiliary_box': {
    template: `
      <div class="prop-group">
        <div class="prop-group-title">辅助块配置</div>
        <el-form size="small" label-width="80px">
          <el-form-item label="高度"><el-input-number v-model="item.heightConfig.val" :min="0" :max="200" controls-position="right" style="width:100%" /></el-form-item>
          <el-form-item label="左右间距"><el-input-number v-model="item.lrEdge.val" :min="0" :max="50" controls-position="right" style="width:100%" /></el-form-item>
        </el-form>
      </div>
    `,
    props: { item: Object }
  },
  'video': {
    template: `
      <div class="prop-group">
        <div class="prop-group-title">视频配置</div>
        <el-form size="small" label-width="80px">
          <el-form-item label="视频地址"><el-input v-model="item.videoConfig.url" size="small" placeholder="https://...mp4" /></el-form-item>
          <el-form-item label="封面图"><DiyUploadImg v-model="item.videoConfig.poster" /></el-form-item>
        </el-form>
      </div>
    `,
    props: { item: Object }
  },
  'hotspot': {
    template: `
      <div class="prop-group">
        <div class="prop-group-title">热区配置</div>
        <el-form size="small" label-width="80px">
          <el-form-item label="底图URL"><DiyUploadImg v-model="item.hotspotConfig.img" /></el-form-item>
          <el-form-item label="热区列表">
            <div v-for="(h,i) in item.hotspotConfig.list" :key="i" class="prop-item" style="border:1px solid #E8ECF1;border-radius:6px;padding:6px;margin-bottom:6px">
              <div style="display:flex;gap:4px;align-items:center;margin-bottom:4px">
                <span style="font-size:12px;color:#909399">热区{{ i+1 }}</span>
                <el-button size="mini" type="text" icon="el-icon-delete" @click="item.hotspotConfig.list.splice(i,1)"></el-button>
              </div>
              <div style="display:flex;gap:4px;margin-bottom:4px">
                <el-input-number v-model="h.x" size="mini" :min="0" :max="100" controls-position="right" /><span style="font-size:12px;line-height:28px">X%</span>
                <el-input-number v-model="h.y" size="mini" :min="0" :max="100" controls-position="right" /><span style="font-size:12px;line-height:28px">Y%</span>
              </div>
              <div style="display:flex;gap:4px;margin-bottom:4px">
                <el-input-number v-model="h.w" size="mini" :min="1" :max="100" controls-position="right" /><span style="font-size:12px;line-height:28px">宽%</span>
                <el-input-number v-model="h.h" size="mini" :min="1" :max="100" controls-position="right" /><span style="font-size:12px;line-height:28px">高%</span>
              </div>
              <DiyLinkPicker v-model="h.link" />
            </div>
            <el-button size="mini" style="width:100%" @click="item.hotspotConfig.list.push({x:10,y:10,w:20,h:20,link:''})">+ 添加热区</el-button>
          </el-form-item>
        </el-form>
      </div>
    `,
    props: { item: Object }
  },
  'customerService': {
    template: `
      <div class="prop-group">
        <div class="prop-group-title">悬浮按钮配置</div>
        <el-form size="small" label-width="80px">
          <el-form-item label="按钮文字"><el-input v-model="item.buttonText.val" size="small" /></el-form-item>
          <el-form-item label="按钮图标"><DiyUploadImg v-model="item.logoConfig.url" /></el-form-item>
          <el-form-item label="展示位置">
            <el-radio-group v-model="item.locationConfig.tabVal" size="small">
              <el-radio-button :label="0">左侧</el-radio-button>
              <el-radio-button :label="1">右侧</el-radio-button>
            </el-radio-group>
          </el-form-item>
          <el-form-item label="跳转类型">
            <el-radio-group v-model="item.buttonConfig.tabVal" size="small">
              <el-radio-button :label="0">页面链接</el-radio-button>
              <el-radio-button :label="1">客服入口</el-radio-button>
            </el-radio-group>
          </el-form-item>
          <el-form-item v-if="item.buttonConfig.tabVal === 0" label="跳转链接"><DiyLinkPicker v-model="item.logoConfig.link" /></el-form-item>
        </el-form>
      </div>
    `,
    props: { item: Object }
  },
  'wechat_attention': {
    template: `
      <div class="prop-group">
        <div class="prop-group-title">公众号配置</div>
        <el-form size="small" label-width="80px">
          <el-form-item label="标题"><el-input v-model="item.titleConfig.value" size="small" /></el-form-item>
          <el-form-item label="头像URL"><DiyUploadImg v-model="item.imgConfig.url" /></el-form-item>
          <el-form-item label="二维码URL"><DiyUploadImg v-model="item.codeConfig.url" /></el-form-item>
        </el-form>
      </div>
    `,
    props: { item: Object }
  },
  'tabNav': {
    template: `
      <div class="prop-group">
        <div class="prop-group-title">选项卡配置</div>
        <el-form size="small" label-width="80px">
          <el-form-item label="选项卡列表">
            <div v-for="(t,i) in item.tabListConfig.list" :key="i" class="prop-item" style="border:1px solid #E8ECF1;border-radius:6px;padding:6px;margin-bottom:6px">
              <div style="display:flex;gap:4px;align-items:center;margin-bottom:4px">
                <span style="font-size:12px;color:#909399">Tab{{ i+1 }}</span>
                <el-button size="mini" type="text" icon="el-icon-delete" @click="item.tabListConfig.list.splice(i,1)"></el-button>
              </div>
              <el-input v-model="t.text.val" size="mini" placeholder="显示文字" style="margin-bottom:4px" />
              <DiyLinkPicker v-model="t.link" />
            </div>
            <el-button size="mini" style="width:100%" @click="item.tabListConfig.list.push({text:{val:'新选项卡'},link:''})">+ 添加选项卡</el-button>
          </el-form-item>
          <el-form-item label="滑动置顶">
            <el-radio-group v-model="item.stickyConfig.tabVal" size="small">
              <el-radio-button :label="0">启用</el-radio-button>
              <el-radio-button :label="1">不启用</el-radio-button>
            </el-radio-group>
          </el-form-item>
        </el-form>
      </div>
    `,
    props: { item: Object }
  },
  // ============ 业务组件配置面板（数据驱动，移动端渲染时调用业务接口） ============
  'device-list': {
    template: `
      <div class="prop-group">
        <div class="prop-group-title">内容设置</div>
        <el-form size="small" label-width="90px">
          <el-form-item label="组件标题"><el-input v-model="item.titleConfig.val" size="mini" /></el-form-item>
          <el-form-item label="显示数量"><el-input-number v-model="item.limitConfig.val" :min="1" :max="50" size="mini" /></el-form-item>
          <el-form-item label="点击链接"><DiyLinkPicker v-model="item.linkConfig.val" /></el-form-item>
        </el-form>
      </div>
    `,
    props: { item: Object }
  },
  'repair-list': {
    template: `
      <div class="prop-group">
        <div class="prop-group-title">内容设置</div>
        <el-form size="small" label-width="90px">
          <el-form-item label="组件标题"><el-input v-model="item.titleConfig.val" size="mini" /></el-form-item>
          <el-form-item label="显示数量"><el-input-number v-model="item.limitConfig.val" :min="1" :max="50" size="mini" /></el-form-item>
          <el-form-item label="点击链接"><DiyLinkPicker v-model="item.linkConfig.val" /></el-form-item>
        </el-form>
      </div>
    `,
    props: { item: Object }
  },
  'hazard-list': {
    template: `
      <div class="prop-group">
        <div class="prop-group-title">内容设置</div>
        <el-form size="small" label-width="90px">
          <el-form-item label="组件标题"><el-input v-model="item.titleConfig.val" size="mini" /></el-form-item>
          <el-form-item label="显示数量"><el-input-number v-model="item.limitConfig.val" :min="1" :max="50" size="mini" /></el-form-item>
          <el-form-item label="点击链接"><DiyLinkPicker v-model="item.linkConfig.val" /></el-form-item>
        </el-form>
      </div>
    `,
    props: { item: Object }
  },
  'inventory-alert': {
    template: `
      <div class="prop-group">
        <div class="prop-group-title">内容设置</div>
        <el-form size="small" label-width="90px">
          <el-form-item label="组件标题"><el-input v-model="item.titleConfig.val" size="mini" /></el-form-item>
          <el-form-item label="显示数量"><el-input-number v-model="item.limitConfig.val" :min="1" :max="50" size="mini" /></el-form-item>
          <el-form-item label="点击链接"><DiyLinkPicker v-model="item.linkConfig.val" /></el-form-item>
        </el-form>
      </div>
    `,
    props: { item: Object }
  },
}

export default {
  name: 'CrmebPageEditor',
  // 动态注册专属属性面板组件为 prop-xxx 命名（对应模板 <component :is="'prop-'+name">）
  components: Object.assign(
    { draggable, DiyUploadImg, DiyLinkPicker },
    Object.keys(propComponents).reduce((acc, key) => {
      acc['prop-' + key] = Object.assign({ components: { DiyUploadImg, DiyLinkPicker } }, propComponents[key])
      return acc
    }, {})
  ),
  data() {
    return {
      componentDefs: C_COMPONENT_DEFS,
      pageId: 0,
      pageName: '首页',
      status: 0,
      // 访问权限（B方案）
      accessType: 'public',
      accessRule: [],
      rolesOptions: [],
      usersOptions: [],
      accessDialogVisible: false,
      activeIndex: -1,
      componentList: [],
      saving: false,
      history: [],
      // iframe 实时预览模式（默认关闭：默认显示可编辑画布，可点击组件配置；预览按钮切换为 iframe 实时预览）
      previewMode: false,
      iframeSrc: '',
      // 系统底部导航（后端 /api/mobile/tab-config，画布底部实时显示）
      liveTabs: [],
    }
  },
  watch: {
    componentList: {
      handler() {
        this.syncPreviewData()
      },
      deep: true,
    },
  },
  computed: {
    selectedComponent() {
      return this.activeIndex >= 0 ? this.componentList[this.activeIndex] : null
    },
    // 访问权限预览文字（B方案）
    accessPreviewText() {
      if (this.accessType === 'public') return '所有人可访问'
      if (this.accessType === 'login') return '仅登录用户可访问'
      if (this.accessType === 'role') {
        const names = this.rolesOptions.filter(r => this.accessRule.includes(r.value)).map(r => r.label)
        return names.length ? '仅 ' + names.join('、') + ' 可访问' : '未选择角色'
      }
      if (this.accessType === 'user') {
        const names = this.usersOptions.filter(u => this.accessRule.includes(u.value)).map(u => u.label)
        return names.length ? '仅 ' + names.join('、') + ' 可访问' : '未选择用户'
      }
      return ''
    },
  },
  created() {
    this.loadPage()
    this.loadAccessOptions()
    this.loadLiveTabs()
    // 初始化 iframe 实时预览地址
    this.iframeSrc = '/h5/#/pages/diy/index?type=home&_t=' + Date.now()
    this.syncPreviewData()
  },
  methods: {
    /** 加载页面 */
    async loadPage() {
      const id = this.$route.params.id || 0
      this.pageId = parseInt(id) || 0
      if (this.pageId) {
        try {
          const res = await diyDetail(this.pageId)
          if (res.code === 0 && res.data) {
            this.pageName = res.data.name || '页面'
            this.status = res.data.status || 0
            // 访问权限回显（B方案）
            this.accessType = res.data.access_type || 'public'
            this.accessRule = Array.isArray(res.data.access_rule) ? res.data.access_rule : []
            const val = res.data.value
            if (val && typeof val === 'object') {
              // CRMEB 结构：以 id 为 key 的对象 → 转数组
              this.componentList = Object.values(val).map(v => this.normalizeComp(v))
            } else if (Array.isArray(val)) {
              this.componentList = val.map(v => this.normalizeComp(v))
            }
            // 同步到 iframe 实时预览
            this.syncPreviewData()
            this.iframeSrc = '/h5/#/pages/diy/index?type=home&_t=' + Date.now()
          }
        } catch (e) {}
      }
    },
    /** 加载角色/用户下拉选项（B方案权限配置） */
    async loadAccessOptions() {
      try {
        const [r1, r2] = await Promise.all([getRoleOptions(), getUserOptions()])
        if (r1.code === 0) this.rolesOptions = r1.data || []
        if (r2.code === 0) this.usersOptions = r2.data || []
      } catch (e) {}
    },
    /** 加载系统底部导航（后端 tab-config，画布底部实时显示） */
    async loadLiveTabs() {
      try {
        const res = await request({ url: '/mobile/tab-config', method: 'get' })
        if (res.code === 0 && res.data && Array.isArray(res.data.list)) {
          this.liveTabs = res.data.list
        }
      } catch (e) {}
    },
    /** 底部导航图标：图片URL 显示图片，uview 图标名映射 emoji，否则取标题首字 */
    footIcon(tab) {
      const icon = (tab && tab.icon) || ''
      if (icon && (icon.startsWith('http://') || icon.startsWith('https://') || icon.startsWith('/uploads') || icon.startsWith('data:'))) {
        return { type: 'img', url: icon }
      }
      const map = { home: '🏠', 'home-fill': '🏠', account: '👤', 'account-fill': '👤', bell: '🔔', 'bell-fill': '🔔', setting: '⚙️', 'setting-fill': '⚙️' }
      const text = map[icon] || ((tab && tab.title) || '').substring(0, 1) || '·'
      return { type: 'text', text }
    },
    normalizeComp(v) {
      if (!v.id) v.id = 'id' + (v.timestamp || Date.now())
      // 兼容旧数据：补齐通用样式字段（对应 crmeb-diy-config.js 的 COMMON_STYLE）
      if (!v.fillet) v.fillet = { title: '组件圆角', type: 0, list: [{ val: '全部' }, { val: '单个' }], valName: '圆角值', val: 0, min: 0, valList: [{ val: 0 }, { val: 0 }, { val: 0 }, { val: 0 }] }
      if (!v.shadowConfig) v.shadowConfig = { title: '组件阴影', color: '#888', x: 0, y: 0, blur: 0, spread: 0, visible: 0 }
      if (!v.prConfig) v.prConfig = { title: '左右边距', val: 0, min: 0 }
      if (!v.mbConfig) v.mbConfig = { title: '页面上间距', val: 0, min: 0 }
      if (!v.offsetYConfig) v.offsetYConfig = { title: '组件上浮', val: 0, min: 0 }
      // 兼容旧数据：banner 专属配置字段
      if (v.name === 'banner') {
        if (!v.docConfig) v.docConfig = { title: '指示器样式', tabVal: 0, tabList: [{ name: '样式一' }, { name: '样式二' }, { name: '样式三' }, { name: '样式四' }] }
        if (!v.docPosition) v.docPosition = { title: '指示器位置', tabVal: 1, tabList: [{ name: '左对齐' }, { name: '居中对齐' }, { name: '右对齐' }] }
        if (!v.toneConfig) v.toneConfig = { title: '色调', tabVal: 0, tabList: [{ name: '跟随主题风格' }, { name: '自定义' }] }
        if (!v.dotColor) v.dotColor = { title: '选中样式', default: [{ item: '#E93323' }], color: [{ item: '#E93323' }] }
        if (!v.dotBgColor) v.dotBgColor = { title: '常规样式', default: [{ item: '#DDDDDD' }], color: [{ item: '#DDDDDD' }] }
        if (!v.filletImg) v.filletImg = { title: '图片圆角', type: 0, list: [{ val: '全部' }, { val: '单个' }], valName: '圆角值', val: 0, min: 0, valList: [{ val: 0 }, { val: 0 }, { val: 0 }, { val: 0 }] }
        if (!v.imgConfig) v.imgConfig = { title: '图片间距', val: 1, min: 0 }
        if (!v.imgShadowConfig) v.imgShadowConfig = { title: '图片阴影', color: '#888', x: 0, y: 0, blur: 0, spread: 0, visible: 0 }
      }
      // 兼容旧数据：home_menu 专属配置字段
      if (v.name === 'home_menu') {
        if (!v.menuStyleConfig) v.menuStyleConfig = { title: '导航样式', tabVal: 0, tabList: [{ name: '图片加文字' }, { name: '方形图标' }, { name: '圆形图标' }, { name: '纯文字' }] }
        if (!v.number) v.number = { title: '单行显示', tabVal: 1, tabList: [{ name: '3个' }, { name: '4个' }, { name: '5个' }] }
        if (!v.showConfig) v.showConfig = { title: '展示样式', tabVal: 0, tabList: [{ name: '固定显示' }, { name: '滑动显示' }] }
        if (!v.rowsNum) v.rowsNum = { title: '显示行数', tabVal: 0, tabList: [{ name: '1行' }, { name: '2行' }] }
        if (!v.filletImg) v.filletImg = { title: '背景圆角', type: 0, list: [{ val: '全部' }, { val: '单个' }], valName: '圆角值', val: 0, min: 0, valList: [{ val: 0 }, { val: 0 }, { val: 0 }, { val: 0 }] }
        if (!v.imgShadowConfig) v.imgShadowConfig = { title: '图标阴影', color: '#888', x: 0, y: 0, blur: 0, spread: 0, visible: 0 }
        if (!v.toneConfig) v.toneConfig = { title: '色调', tabVal: 0, tabList: [{ name: '跟随主题风格' }, { name: '自定义' }] }
        if (!v.pointerColor) v.pointerColor = { title: '选中样式', default: [{ item: '#E93323' }], color: [{ item: '#E93323' }] }
        if (!v.pointerBgColor) v.pointerBgColor = { title: '常规样式', default: [{ item: '#DDDDDD' }], color: [{ item: '#DDDDDD' }] }
        if (!v.textColor) v.textColor = { title: '文字颜色', default: [{ item: '#333' }], color: [{ item: '#333' }] }
      }
      // 兼容旧数据：home_title 右侧按钮配置
      if (v.name === 'home_title') {
        if (!v.buttonConfig) v.buttonConfig = { title: '是否显示按钮', tabVal: 0, tabList: [{ name: '显示' }, { name: '不显示' }] }
        if (!v.linkConfig) v.linkConfig = { title: '链接地址', val: '' }
        if (!v.buttonColor) v.buttonColor = { title: '按钮颜色', default: [{ item: '#4F46E5' }], color: [{ item: '#4F46E5' }] }
        if (!v.buttonText) v.buttonText = { title: '按钮文字', val: '更多' }
      }
      // 兼容旧数据：富文本内边距
      if (v.name === 'richText') {
        if (!v.lrConfig) v.lrConfig = { title: '左右内边距', val: 0, min: 0 }
        if (!v.udConfig) v.udConfig = { title: '上下内边距', val: 0, min: 0 }
      }
      // 兼容旧数据：图片魔方
      if (v.name === 'picture_cube') {
        if (!v.styleConfig) v.styleConfig = { title: '选择风格', tabVal: 0, tabList: [{ name: '样式一' }, { name: '样式二' }] }
        if (!v.titleShow) v.titleShow = { title: '标题显示', tabVal: 0, tabList: [{ name: '显示' }, { name: '不显示' }] }
        if (!v.imgConfig) v.imgConfig = { title: '图片间距', val: 1, min: 0 }
        if (!v.filletImg) v.filletImg = { title: '图片圆角', type: 0, list: [{ val: '全部' }, { val: '单个' }], valName: '圆角值', val: 0, min: 0, valList: [{ val: 0 }, { val: 0 }, { val: 0 }, { val: 0 }] }
        if (!v.imgShadowConfig) v.imgShadowConfig = { title: '图片阴影', color: '#888', x: 0, y: 0, blur: 0, spread: 0, visible: 0 }
      }
      // 兼容旧数据：搜索框
      if (v.name === 'search_box') {
        if (!v.fixedConfig) v.fixedConfig = { title: '是否固定', tabVal: 0, tabList: [{ name: '固定' }, { name: '不固定' }] }
        if (!v.styleConfig) v.styleConfig = { title: '选择风格', tabVal: 0, tabList: [{ name: '样式一' }, { name: '样式二' }, { name: '样式三' }] }
        if (!v.logoConfig) v.logoConfig = { title: '左侧图标', url: '', link: '' }
        if (!v.titleSearch) v.titleSearch = { title: '是否显示按钮', tabVal: 1, tabList: [{ name: '显示' }, { name: '不显示' }] }
        if (!v.btnTextConfig) v.btnTextConfig = { title: '按钮文字', val: '搜索' }
      }
      // 兼容旧数据：公告
      if (v.name === 'news_roll') {
        if (!v.styleConfig) v.styleConfig = { title: '选择风格', tabVal: 0, tabList: [{ name: '横向滚动' }, { name: '纵向滚动' }] }
        if (!v.titleStyle) v.titleStyle = { title: '标题样式', tabVal: 0, tabList: [{ name: '显示' }, { name: '不显示' }] }
        if (!v.titleConfig) v.titleConfig = { title: '标题文字', val: '公告' }
        if (!v.rollConfig) v.rollConfig = { title: '滚动速度', val: 5, min: 1, max: 20 }
      }
      // 兼容旧数据：辅助线/辅助块 左右间距
      if (v.name === 'z_auxiliary_line') {
        if (!v.lineStyle) v.lineStyle = { title: '线条样式', tabVal: 0, tabList: [{ name: '实线' }, { name: '虚线' }, { name: '点线' }] }
        if (!v.lineBgColor) v.lineBgColor = { title: '背景颜色', default: [{ item: '#fff' }], color: [{ item: '#fff' }] }
        if (!v.lrEdge) v.lrEdge = { title: '左右间距', val: 0, min: 0 }
      }
      if (v.name === 'z_auxiliary_box') {
        if (!v.lrEdge) v.lrEdge = { title: '左右间距', val: 0, min: 0 }
      }
      return v
    },
    /** 添加组件 */
    addComponent(comp) {
      const ts = genTs()
      const newItem = JSON.parse(JSON.stringify(comp.defaultConfig))
      newItem.id = 'id' + ts
      newItem.timestamp = ts
      this.componentList.push(newItem)
      this.activeIndex = this.componentList.length - 1
      this.saveHistory()
    },
    /** 选中组件 */
    selectComponent(index) {
      this.activeIndex = this.activeIndex === index ? -1 : index
    },
    /** 组件图标映射 */
    itemIcon(name) {
      const map = {
        banner: 'el-icon-picture', home_menu: 'el-icon-menu', home_title: 'el-icon-edit-outline',
        richText: 'el-icon-document', picture_cube: 'el-icon-grid', search_box: 'el-icon-search',
        news_roll: 'el-icon-bell', z_auxiliary_line: 'el-icon-minus', z_auxiliary_box: 'el-icon-crop',
        video: 'el-icon-video-camera', hotspot: 'el-icon-location-outline', customerService: 'el-icon-service',
        wechat_attention: 'el-icon-message', tabNav: 'el-icon-s-operation',
        profile_menu: 'el-icon-user'
      }
      return map[name] || 'el-icon-box'
    },
    /** 删除组件 */
    removeComponent(index) {
      this.componentList.splice(index, 1)
      this.activeIndex = -1
      this.saveHistory()
    },
    /** 保存历史（用于撤销，预留） */
    saveHistory() {},
    /** 是否有专属属性组件 */
    hasPropComponent(name) {
      return !!propComponents[name]
    },
    /** 保存 */
    async handleSave() {
      this.saving = true
      try {
        // 将数组转为 CRMEB 的"以 id 为 key 的对象"格式
        // 注意：key 必须加非数字前缀(c)，否则 JS 对象整数键会自动按数字升序重排，
        // 导致拖拽后的组件顺序在保存/渲染时丢失（永远按添加时间排序）
        const valueObj = {}
        this.componentList.forEach(item => {
          valueObj['c' + (item.timestamp || Date.now())] = JSON.parse(JSON.stringify(item))
        })
        await diySave(this.pageId, {
          name: this.pageName,
          title: this.pageName,
          value: valueObj,
          // 访问权限（B方案）
          access_type: this.accessType,
          access_rule: (this.accessType === 'role' || this.accessType === 'user') ? this.accessRule : null,
        })
        this.$message.success('保存成功')
      } catch (e) {
        this.$message.error(e.message || '保存失败')
      }
      this.saving = false
    },
    /** 切换 编辑画布 / iframe 实时预览 */
    togglePreview() {
      if (this.previewMode) {
        // 返回编辑
        this.previewMode = false
      } else {
        // 进入预览
        this.syncPreviewData()
        this.previewMode = true
        this.iframeSrc = '/h5/#/pages/diy/index?type=home&_t=' + Date.now()
      }
    },
    /** 刷新 iframe 实时预览 */
    refreshPreview() {
      this.syncPreviewData()
      this.iframeSrc = '/h5/#/pages/diy/index?type=home&_t=' + Date.now()
    },
    /** 同步编辑数据到 localStorage（iframe 预览读取） */
    syncPreviewData() {
      try {
        const items = this.componentList.map(c => JSON.parse(JSON.stringify(c)))
        localStorage.setItem('diy_preview_data', JSON.stringify({ items, page: { bgColor: '#f5f6fa' } }))
      } catch (e) {}
    },
    /** 判断可编辑属性 */
    isEditableProp(k) {
      // 通用样式字段已在「基础设置/样式设置」专属面板处理，避免在此重复渲染
      return ['bgColor', 'txtColor', 'activeTxtColor', 'topConfig', 'bottomConfig'].includes(k)
    },
    /** 画布预览通用样式（与移动端 itemStyle 对齐） */
    pvStyle(item) {
      const s = {}
      const mb = item.mbConfig?.val || 0
      const offset = item.offsetYConfig?.val || 0
      if (offset) s.marginTop = -offset + 'px'
      else if (mb) s.marginTop = mb + 'px'
      if (item.topConfig?.val) s.paddingTop = item.topConfig.val + 'px'
      if (item.bottomConfig?.val) s.paddingBottom = item.bottomConfig.val + 'px'
      if (item.prConfig?.val) { s.paddingLeft = item.prConfig.val + 'px'; s.paddingRight = item.prConfig.val + 'px' }
      if (item.fillet?.val) s.borderRadius = item.fillet.val + 'px'
      if (item.shadowConfig && item.shadowConfig.visible) {
        const sh = item.shadowConfig
        s.boxShadow = `${sh.x||0}px ${sh.y||0}px ${sh.blur||0}px ${sh.spread||0}px ${sh.color||'#888'}`
      }
      return s
    },
    /** 阴影样式辅助（与移动端 shadowStyle 一致） */
    shadowStyle(config) {
      if (!config) return 'none'
      if (config.visible == 0 || (config.x == 0 && config.y == 0 && config.blur == 0 && config.spread == 0)) return 'none'
      return `${config.x||0}px ${config.y||0}px ${config.blur||0}px ${config.spread||0}px ${config.color||'#888'}`
    },
    /** 画布预览跳转（新窗口打开链接） */
    navigatePreview(url) {
      if (!url) return
      if (url.startsWith('/pages') || url.startsWith('/h5')) {
        window.open(window.location.origin + '/h5/#' + url)
      } else if (url.startsWith('http')) {
        window.open(url)
      }
    },
    /** 图片完整URL（处理上传返回的相对路径 /uploads/...） */
    toFullUrl(val) {
      if (!val) return ''
      if (val.startsWith('http://') || val.startsWith('https://') || val.startsWith('data:')) return val
      if (val.startsWith('/')) return window.location.origin + val
      return val
    },
    isColorProp(v) { return v && v.color && Array.isArray(v.color) },
    isSliderProp(v) { return v && typeof v === 'object' && 'val' in v && 'min' in v },
    isTextProp(v) { return v && typeof v === 'object' && 'val' in v && !('min' in v) },
    goBack() { this.$router.push('/diy/list') },
  },
}
</script>

<style scoped>
.crmeb-diy-editor { height: 100vh; display: flex; flex-direction: column; background: #f0f2f5; margin: -20px; }
.editor-toolbar { display: flex; align-items: center; padding: 0 12px; height: 52px; background: #fff; border-bottom: 1px solid #e8ecf1; flex-shrink: 0; }
.editor-body { display: flex; flex: 1; overflow: hidden; min-height: 0; }

/* 左侧组件库 */
.component-panel { width: 220px; background: #F8F9FA; border-right: 1px solid #E8ECF1; display: flex; flex-direction: column; flex-shrink: 0; }
.panel-header { display: flex; align-items: center; justify-content: space-between; height: 44px; padding: 0 12px; flex-shrink: 0; }
.panel-title { font-size: 15px; font-weight: 600; color: #303133; }
.panel-count { font-size: 12px; color: #909399; }
.panel-scroll { flex: 1; overflow-y: auto; }
.component-group { padding: 4px 0; }
.group-title { padding: 8px 12px; font-size: 13px; color: #909399; }
.component-item { display: flex; align-items: center; gap: 6px; padding: 0 12px; height: 36px; cursor: pointer; transition: all .15s; border-radius: 4px; margin: 1px 4px; }
.component-item:hover { background: #E8EDF3; }
.page-comp-item { position: relative; border: 1px solid transparent; }
.page-comp-active { border-color: #409eff; background: #E8F1FF; }
.page-comp-del { color: #f56c6c; opacity: 0; margin-left: auto; }
.page-comp-item:hover .page-comp-del { opacity: 1; }
.comp-name { font-size: 13px; color: #606266; flex: 1; }

/* 中间画布 */
.canvas-wrap { flex: 1; padding: 16px; overflow: auto; display: flex; justify-content: center; background: #e8ecf1; }
/* iframe 实时预览 */
.canvas-preview { width: 375px; display: flex; flex-direction: column; background: #f5f6fa; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }
.preview-toolbar { display: flex; align-items: center; justify-content: space-between; padding: 8px 12px; background: #fff; border-bottom: 1px solid #E8ECF1; }
.preview-frame { width: 100%; height: 700px; border: none; background: #f5f6fa; }
.canvas { width: 375px; min-height: 700px; background: #f5f6fa; border-radius: 16px; padding: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }
.canvas-list { min-height: 100px; }
.canvas-item { position: relative; background: #fff; border-radius: 8px; margin-bottom: 8px; border: 2px solid transparent; transition: all 0.2s; cursor: pointer; overflow: hidden; }
.canvas-item.active { border-color: #409eff; box-shadow: 0 0 0 2px rgba(64,158,255,0.15); }
.canvas-item-toolbar { display: flex; align-items: center; justify-content: space-between; padding: 4px 8px; background: #fafafa; border-bottom: 1px solid #f0f0f0; }
.item-name { font-size: 12px; color: #909399; }
.el-icon-delete { color: #f56c6c; cursor: pointer; }
.item-preview { min-height: 30px; }
.pv-banner { position: relative; background: #f5f6fa; }
.pv-banner-imgwrap { position: relative; overflow: hidden; }
.pv-banner-dots { display: flex; align-items: center; gap: 4px; padding: 6px 10px; }
.pv-banner-dot { width: 12px; height: 4px; border-radius: 2px; }
.pv-menu { display: grid; gap: 8px; padding: 16px 12px; background: #fff; border-radius: 16px; margin: 0 12px; }
.pv-menu-item { display: flex; flex-direction: column; align-items: center; gap: 4px; font-size: 12px; color: #333; }
.pv-title-row { display: flex; align-items: center; padding: 0 12px; }
.pv-title { padding: 12px 16px; line-height: 1.4; }
.pv-title-btn { font-size: 13px; margin-left: 12px; flex-shrink: 0; cursor: pointer; }
.pv-rich { padding: 12px; }
.pv-cube { display: flex; flex-wrap: wrap; gap: 6px; padding: 0 12px; }
.pv-search { display: flex; align-items: center; gap: 8px; padding: 8px 12px; }
.pv-search input { flex: 1; height: 36px; border: 1px solid #ddd; border-radius: 8px; padding: 0 12px; font-size: 14px; background: #f5f7fa; }
.pv-search-btn { padding: 6px 14px; background: #4F46E5; color: #fff; font-size: 13px; border-radius: 8px; }
.pv-news { display: flex; align-items: center; gap: 6px; padding: 10px 14px; background: #FFF8E1; color: #F59E0B; font-size: 13px; border-radius: 8px; margin: 0 12px; }
.pv-news-title { flex-shrink: 0; font-weight: 600; }
.pv-tabnav { display: flex; white-space: nowrap; }
.pv-tabnav-item { display: inline-flex; align-items: center; padding: 12px 18px; font-size: 14px; color: #666; border-bottom: 2px solid transparent; }
.pv-tabnav-item.active { font-weight: 600; }
.pv-service { display: flex; padding: 0 12px; }
.pv-service-btn { display: inline-flex; align-items: center; gap: 6px; padding: 10px 18px; border-radius: 24px; box-shadow: 0 4px 12px rgba(0,0,0,0.15); }
.pv-wechat { display: flex; align-items: center; justify-content: space-between; margin: 0 12px; padding: 10px 12px; background: #fff; border-radius: 8px; }
.pv-wechat-left { display: flex; align-items: center; gap: 10px; }
.pv-wechat-avatar { width: 36px; height: 36px; border-radius: 50%; overflow: hidden; background: #f5f7fa; display: flex; align-items: center; justify-content: center; }
.pv-wechat-btn { font-size: 13px; padding: 5px 16px; border: 1px solid currentColor; border-radius: 20px; }
.pv-pagefoot { display: flex; background: #fff; }
.pv-pagefoot-item { flex: 1; display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 8px 0; gap: 2px; }
/* 画布底部固定底部导航 */
.canvas { display: flex; flex-direction: column; }
.canvas-scroll { flex: 1; overflow-y: auto; min-height: 0; }
.canvas-footbar { display: flex; background: #fff; border-top: 1px solid #E8ECF1; border-radius: 0 0 16px 16px; flex-shrink: 0; cursor: pointer; }
.canvas-footbar.footbar-active { box-shadow: 0 0 0 2px #409eff; }
.canvas-footbar-item { flex: 1; display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 8px 0; gap: 2px; }
.pv-unknown { padding: 20px; text-align: center; color: #909399; }
/* 业务组件画布预览占位 */
.pv-biz { padding: 12px; background: #fafbfc; border: 1px dashed #d9dde3; border-radius: 8px; }
.pv-biz-head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 10px; }
.pv-biz-title { font-size: 14px; font-weight: 600; color: #303133; }
.pv-biz-badge { font-size: 11px; color: #fff; background: #409EFF; border-radius: 4px; padding: 1px 6px; }
.pv-biz-body { display: flex; flex-direction: column; gap: 6px; }
.pv-biz-row { display: flex; gap: 8px; align-items: center; }
.pv-biz-line { height: 10px; background: #e4e7ed; border-radius: 4px; }
.pv-biz-note { margin-top: 8px; font-size: 11px; color: #C0C4CC; }
.empty-state { text-align: center; color: #c0c4cc; padding: 80px 0; }
.empty-icon { font-size: 48px; margin-bottom: 12px; }
.empty-text { font-size: 14px; }

/* 右侧属性面板 */
.property-panel { width: 320px; min-width: 320px; background: #fff; border-left: 1px solid #e8ecf1; padding: 0 0 12px 0; overflow-y: auto; flex-shrink: 0; }
.property-header { padding: 12px 12px 8px; }
.section-title { font-size: 14px; font-weight: 600; color: #303133; margin-bottom: 10px; padding-bottom: 6px; border-bottom: 1px solid #f0f0f0; }
.property-section { margin-bottom: 16px; }
/* CRMEB 风格分组：灰色分隔条 + 分组标题 */
.prop-group { padding: 0 12px; }
.prop-group + .prop-group { margin-top: 0; }
.prop-group-title { font-size: 14px; font-weight: 600; color: #303133; margin-bottom: 10px; padding: 12px 0 8px; border-top: 6px solid #f0f2f5; }
.prop-group .el-form-item { margin-bottom: 14px; }
.empty-property { text-align: center; color: #c0c4cc; padding: 40px 0; }
.empty-property .empty-icon { font-size: 36px; margin-bottom: 8px; }
.empty-property .empty-text { font-size: 13px; }
.prop-item { background: #f5f7fa; border-radius: 4px; padding: 6px; margin-bottom: 6px; }
</style>
