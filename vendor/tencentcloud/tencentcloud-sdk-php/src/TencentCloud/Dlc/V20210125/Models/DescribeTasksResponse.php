<?php
/*
 * Copyright (c) 2017-2025 Tencent. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
namespace TencentCloud\Dlc\V20210125\Models;
use TencentCloud\Common\AbstractModel;

/**
 * DescribeTasks返回参数结构体
 *
 * @method array getTaskList() 获取<p>任务对象列表。</p>
 * @method void setTaskList(array $TaskList) 设置<p>任务对象列表。</p>
 * @method integer getTotalCount() 获取<p>实例总数。</p>
 * @method void setTotalCount(integer $TotalCount) 设置<p>实例总数。</p>
 * @method TasksOverview getTasksOverview() 获取<p>任务概览信息</p>
注意：此字段可能返回 null，表示取不到有效值。
 * @method void setTasksOverview(TasksOverview $TasksOverview) 设置<p>任务概览信息</p>
注意：此字段可能返回 null，表示取不到有效值。
 * @method string getRequestId() 获取唯一请求 ID，由服务端生成，每次请求都会返回（若请求因其他原因未能抵达服务端，则该次请求不会获得 RequestId）。定位问题时需要提供该次请求的 RequestId。
 * @method void setRequestId(string $RequestId) 设置唯一请求 ID，由服务端生成，每次请求都会返回（若请求因其他原因未能抵达服务端，则该次请求不会获得 RequestId）。定位问题时需要提供该次请求的 RequestId。
 */
class DescribeTasksResponse extends AbstractModel
{
    /**
     * @var array <p>任务对象列表。</p>
     */
    public $TaskList;

    /**
     * @var integer <p>实例总数。</p>
     */
    public $TotalCount;

    /**
     * @var TasksOverview <p>任务概览信息</p>
注意：此字段可能返回 null，表示取不到有效值。
     */
    public $TasksOverview;

    /**
     * @var string 唯一请求 ID，由服务端生成，每次请求都会返回（若请求因其他原因未能抵达服务端，则该次请求不会获得 RequestId）。定位问题时需要提供该次请求的 RequestId。
     */
    public $RequestId;

    /**
     * @param array $TaskList <p>任务对象列表。</p>
     * @param integer $TotalCount <p>实例总数。</p>
     * @param TasksOverview $TasksOverview <p>任务概览信息</p>
注意：此字段可能返回 null，表示取不到有效值。
     * @param string $RequestId 唯一请求 ID，由服务端生成，每次请求都会返回（若请求因其他原因未能抵达服务端，则该次请求不会获得 RequestId）。定位问题时需要提供该次请求的 RequestId。
     */
    function __construct()
    {

    }

    /**
     * For internal only. DO NOT USE IT.
     */
    public function deserialize($param)
    {
        if ($param === null) {
            return;
        }
        if (array_key_exists("TaskList",$param) and $param["TaskList"] !== null) {
            $this->TaskList = [];
            foreach ($param["TaskList"] as $key => $value){
                $obj = new TaskResponseInfo();
                $obj->deserialize($value);
                array_push($this->TaskList, $obj);
            }
        }

        if (array_key_exists("TotalCount",$param) and $param["TotalCount"] !== null) {
            $this->TotalCount = $param["TotalCount"];
        }

        if (array_key_exists("TasksOverview",$param) and $param["TasksOverview"] !== null) {
            $this->TasksOverview = new TasksOverview();
            $this->TasksOverview->deserialize($param["TasksOverview"]);
        }

        if (array_key_exists("RequestId",$param) and $param["RequestId"] !== null) {
            $this->RequestId = $param["RequestId"];
        }
    }
}
