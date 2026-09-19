<?php
declare (strict_types = 1);
namespace app\model;

use think\Model;

/**
 * 问卷答卷模型
 */
class SurveyAnswerModel extends Model
{
    protected $name = 'survey_answer';
    protected $autoWriteTimestamp = false;
    protected $jsonAssoc = true;
}
