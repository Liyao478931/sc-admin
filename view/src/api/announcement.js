/**
 * 公告管理 API
 */
import request from './request'

export function getAnnouncementList(params) { return request({ url: '/announcement/list', method: 'get', params }) }
export function getAnnouncementDetail(id) { return request({ url: '/announcement/detail', method: 'get', params: { id } }) }
export function addAnnouncement(data) { return request({ url: '/announcement/add', method: 'post', data }) }
export function editAnnouncement(data) { return request({ url: '/announcement/edit', method: 'post', data }) }
export function toggleAnnouncement(data) { return request({ url: '/announcement/toggle', method: 'post', data }) }
export function deleteAnnouncement(id) { return request({ url: '/announcement/delete', method: 'post', data: { id } }) }
