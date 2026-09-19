<?php
declare (strict_types = 1);
namespace app\model;

use think\Model;

/**
 * 问卷题目模型
 */
class SurveyQuestionModel extends Model
{
    protected $name = 'survey_question';
    protected $autoWriteTimestamp = false;
    protected $jsonAssoc = true;

    /** 题型 */
    public const TYPES = ['radio', 'multi', 'text', 'score'];
}
