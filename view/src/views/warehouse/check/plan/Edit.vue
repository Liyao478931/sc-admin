<!--
  文件：admin/src/views/warehouse/check/plan/Edit.vue
  功能：编辑盘点计划（复用 Add.vue，传入 editId）
-->
<template>
  <PlanAdd :edit-id="planId" />
</template>

<script>
import PlanAdd from './Add.vue'

export default {
  name: 'InventoryPlanEdit',
  components: { PlanAdd },
  data () {
    return { planId: this.$route.params.id || 0 }
  }
}
</script>
