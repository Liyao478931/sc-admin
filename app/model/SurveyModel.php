<?php
declare (strict_types = 1);
namespace app\model;

use think\Model;

/**
 * 问卷主表模型
 */
class SurveyModel extends Model
{
    protected $name = 'survey';
    protected $autoWriteTimestamp = false;
    protected $jsonAssoc = true;

    /** 状态文案 */
    public const STATUS_TEXT = ['草稿', '发布中', '已停止'];

    public function questions()
    {
        return $this->hasMany(SurveyQuestionModel::class, 'survey_id', 'id');
    }

    public function answers()
    {
        return $this->hasMany(SurveyAnswerModel::class, 'survey_id', 'id');
    }
}
