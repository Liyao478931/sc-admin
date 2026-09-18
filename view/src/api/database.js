/**
 * 数据库维护 API
 */
import request from './request'

export function getTableList() { return request({ url: '/database/tables', method: 'get' }) }
export function getTableDetail(name) { return request({ url: `/database/tables/${name}`, method: 'get' }) }
export function getStatistics() { return request({ url: '/database/statistics', method: 'get' }) }
export function getConnectionStatus() { return request({ url: '/database/connection-status', method: 'get' }) }
export function getFragmentation(name) { return request({ url: `/database/tables/${name}/fragmentation`, method: 'get' }) }
export function optimizeTable(name) { return request({ url: `/database/tables/${name}/optimize`, method: 'post' }) }
export function optimizeBatch(tables) { return request({ url: '/database/tables/optimize-batch', method: 'post', data: { tables } }) }
export function repairTable(name) { return request({ url: `/database/tables/${name}/repair`, method: 'post' }) }
export function repairBatch(tables) { return request({ url: '/database/tables/repair-batch', method: 'post', data: { tables } }) }
export function truncateTable(name) { return request({ url: `/database/tables/${name}/truncate`, method: 'post' }) }
export function dropTable(name) { return request({ url: `/database/tables/${name}/drop`, method: 'post' }) }
export function backupDatabase(data) { return request({ url: '/database/backup', method: 'post', data }) }
export function getBackupList() { return request({ url: '/database/backups', method: 'get' }) }
export function deleteBackup(filename) { return request({ url: `/database/backups/${filename}`, method: 'delete' }) }
export function downloadBackup(filename) { return `/api/database/backups/${filename}/download` }
export function restoreBackup(filename, data) { return request({ url: `/database/backups/${filename}/restore`, method: 'post', data }) }
export function getBackupSettings() { return request({ url: '/database/backup-settings', method: 'get' }) }
export function saveBackupSettings(data) { return request({ url: '/database/backup-settings', method: 'put', data }) }
export function getTableNames() { return request({ url: '/database/table-names', method: 'get' }) }
export function saveTableNames(data) { return request({ url: '/database/table-names', method: 'put', data }) }
