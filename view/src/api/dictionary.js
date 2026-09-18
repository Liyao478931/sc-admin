import request from './request'

export function getTypes() { return request({ url: '/dictionary/types', method: 'get' }) }
export function getType(id) { return request({ url: `/dictionary/types/${id}`, method: 'get' }) }
export function createType(data) { return request({ url: '/dictionary/types', method: 'post', data }) }
export function updateType(id, data) { return request({ url: `/dictionary/types/${id}`, method: 'put', data }) }
export function deleteType(id) { return request({ url: `/dictionary/types/${id}`, method: 'delete' }) }

export function getEntries(typeId, keyword) { return request({ url: '/dictionary/entries', method: 'get', params: { type_id: typeId, keyword } }) }
export function getEntry(id) { return request({ url: `/dictionary/entries/${id}`, method: 'get' }) }
export function createEntry(data) { return request({ url: '/dictionary/entries', method: 'post', data }) }
export function updateEntry(id, data) { return request({ url: `/dictionary/entries/${id}`, method: 'put', data }) }
export function deleteEntry(id) { return request({ url: `/dictionary/entries/${id}`, method: 'delete' }) }

export function getDictByCode(code) { return request({ url: `/dictionary/${code}`, method: 'get' }) }
export function getDictBatch(codes) { return request({ url: '/dictionary/batch/get', method: 'get', params: { codes: codes.join(',') } }) }

export function exportDict() { return request({ url: '/dictionary/export', method: 'get' }) }
export function importDict(data) { return request({ url: '/dictionary/import', method: 'post', data: { data } }) }
