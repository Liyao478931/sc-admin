<?php
use think\facade\Route;

/* ============ 问卷管理 · 管理端（需登录+权限） ============ */
Route::get('survey/list', 'SurveyController/list')->middleware(\app\middleware\AuthMiddleware::class);
Route::get('survey/detail', 'SurveyController/detail')->middleware(\app\middleware\AuthMiddleware::class);
Route::post('survey/save', 'SurveyController/save')->middleware(\app\middleware\AuthMiddleware::class);
Route::post('survey/toggle', 'SurveyController/toggle')->middleware(\app\middleware\AuthMiddleware::class);
Route::post('survey/delete', 'SurveyController/delete')->middleware(\app\middleware\AuthMiddleware::class);
Route::post('survey/copy', 'SurveyController/copy')->middleware(\app\middleware\AuthMiddleware::class);
Route::get('survey/stats', 'SurveyController/stats')->middleware(\app\middleware\AuthMiddleware::class);
Route::get('survey/export', 'SurveyController/export')->middleware(\app\middleware\AuthMiddleware::class);

/* ============ 问卷管理 · 公开填写端（无需登录） ============ */
Route::get('survey/view', 'SurveyController/view');
Route::post('survey/submit', 'SurveyController/submit');
