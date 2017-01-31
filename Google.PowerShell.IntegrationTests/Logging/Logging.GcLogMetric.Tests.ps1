﻿. $PSScriptRoot\..\GcloudCmdlets.ps1
Install-GCloudCmdlets

$project, $zone, $oldActiveConfig, $configName = Set-GCloudConfig

Describe "Get-GcLogMetric" {
    $r = Get-Random
    $script:metricName = "gcps-get-gclogmetric-$r"
    $script:metricNameTwo = "gcps-get-gclogmetric-2-$r"
    $logFilter = "this is a filter"
    $logFilterTwo = "this is another filter"
    $description = "This is the first description"
    $descriptionTwo = "This is the second description"
    gcloud beta logging metrics create $script:metricName --description=$description --log-filter=$logFilter --quiet 2>$null
    gcloud beta logging metrics create $script:metricNameTwo --description=$descriptionTwo --log-filter=$logFilterTwo --quiet 2>$null
    

    AfterAll {
        gcloud beta logging metrics delete $metricName --quiet 2>$null
        gcloud beta logging metrics delete $metricNameTwo --quiet 2>$null
    }

    It "should work without any parameters" {
        $metrics = Get-GcLogMetric

        $firstMetric = $metrics | Where-Object {$_.Name -eq $metricName}
        $firstMetric | Should Not BeNullOrEmpty
        $firstMetric.Description | Should BeExactly $description
        $firstMetric.Filter | Should BeExactly $logFilter

        $secondMetric = $metrics | Where-Object {$_.Name -eq $metricNameTwo}
        $secondMetric | Should Not BeNullOrEmpty
        $secondMetric.Description | Should BeExactly $descriptionTwo
        $secondMetric.Filter | Should BeExactly $logFilterTwo
    }

    It "should work with -MetricName parameter" {
        $metric = Get-GcLogMetric -MetricName $metricName
        $metric | Should Not BeNullOrEmpty
        $metric.Name | Should BeExactly "$metricName"
        $metric.Description | Should BeExactly $description
        $metric.Filter | Should BeExactly $logFilter
    }

    It "should work with an array of metrics" {
        $metrics = Get-GcLogMetric -MetricName $metricName, $metricNameTwo
        $metrics.Count | Should Be 2

        $firstMetric = $metrics | Where-Object {$_.Name -eq $metricName}
        $firstMetric | Should Not BeNullOrEmpty
        $firstMetric.Description | Should BeExactly $description
        $firstMetric.Filter | Should BeExactly $logFilter

        $secondMetric = $metrics | Where-Object {$_.Name -eq $metricNameTwo}
        $secondMetric | Should Not BeNullOrEmpty
        $secondMetric.Description | Should BeExactly $descriptionTwo
        $secondMetric.Filter | Should BeExactly $logFilterTwo
    }

    It "should throw an error for non-existent metric" {
        { Get-GcLogMetric -Metric "non-existent-metric-name" -ErrorAction Stop } | Should Throw "does not exist"
    }
}

Describe "New-GcLogMetric" {
    It "should work with -LogName" {
        $r = Get-Random
        $metricName = "gcps-new-gclogmetric-$r"
        $logName = "gcps-new-gclogmetric-log-$r"
        try {
            $createdMetric = New-GcLogMetric $metricName -LogName $logName
            $onlineMetric = Get-GcLogMetric $metricName

            ForEach ($metric in @($createdMetric, $onlineMetric)) {
                $metric | Should Not BeNullOrEmpty
                $metric.Name | Should BeExactly $metricName
                $metric.Filter | Should BeExactly "logName = `"projects/$project/logs/$logName`""
                $metric.Description | Should BeNullOrEmpty
            }
        }
        finally {
            gcloud beta logging metrics delete $metricName --quiet 2>$null
        }
    }

    It "should work with -Before and -After" {
        $r = Get-Random
        $metricName = "gcps-new-gclogmetric-$r"
        $metricNameTwo = "gcps-new-gclogmetric-2-$r"
        $before = [DateTime]::new(2017, 1, 1)
        $after = [DateTime]::new(2017, 12, 12)
        $beforeTimeString = "timestamp <= `"2017-01-01T00:00:00-08:00`""
        $afterTimeString = "timestamp >= `"2017-12-12T00:00:00-08:00`""
        try {
            $createdMetricOne = New-GcLogMetric $metricName -Before $before
            $createdMetricTwo = New-GcLogMetric $metricNameTwo -After $after
            $onlineMetricOne = Get-GcLogMetric $metricName
            $onlineMetricTwo = Get-GcLogMetric $metricNameTwo

            ForEach ($metric in @($createdMetricOne, $onlineMetricOne)) {
                $metric | Should Not BeNullOrEmpty
                $metric.Name | Should BeExactly $metricName
                $metric.Filter | Should BeExactly $beforeTimeString
                $metric.Description | Should BeNullOrEmpty
            }
            
            ForEach ($metric in @($createdMetricTwo, $onlineMetricTwo)) {
                $metric | Should Not BeNullOrEmpty
                $metric.Name | Should BeExactly $metricNameTwo
                $metric.Filter | Should BeExactly $afterTimeString
                $metric.Description | Should BeNullOrEmpty
            }
        }
        finally {
            gcloud beta logging metrics delete $metricName --quiet 2>$null
            gcloud beta logging metrics delete $metricNameTwo --quiet 2>$null
        }
    }

    It "should work with -Severity" {
        $r = Get-Random
        $metricName = "gcps-new-gclogmetric-$r"
        try {
            $createdMetric = New-GcLogMetric $metricName -Severity ERROR
            $onlineMetric = Get-GcLogMetric $metricName

            ForEach ($metric in @($createdMetric, $onlineMetric)) {
                $metric | Should Not BeNullOrEmpty
                $metric.Name | Should BeExactly $metricName
                $metric.Filter | Should BeExactly "severity = ERROR"
                $metric.Description | Should BeNullOrEmpty
            }
        }
        finally {
            gcloud beta logging metrics delete $metricName --quiet 2>$null
        }
    }

    It "should work with -ResourceType" {
        $r = Get-Random
        $metricName = "gcps-new-gclogmetric-$r"
        $resourceType = "gce_instance"
        try {
            $createdMetric = New-GcLogMetric $metricName -ResourceType $resourceType
            $onlineMetric = Get-GcLogMetric $metricName

            ForEach ($metric in @($createdMetric, $onlineMetric)) {
                $metric | Should Not BeNullOrEmpty
                $metric.Name | Should BeExactly $metricName
                $metric.Filter | Should BeExactly "resource.type = `"$resourceType`""
                $metric.Description | Should BeNullOrEmpty
            }
        }
        finally {
            gcloud beta logging metrics delete $metricName --quiet 2>$null
        }
    }

    It "should work with -Filter" {
        $r = Get-Random
        $metricName = "gcps-new-gclogmetric-$r"
        $filter = "textPayload = testing"
        try {
            $createdMetric = New-GcLogMetric $metricName -Filter $filter
            $onlineMetric = Get-GcLogMetric $metricName

            ForEach ($metric in @($createdMetric, $onlineMetric)) {
                $metric | Should Not BeNullOrEmpty
                $metric.Name | Should BeExactly $metricName
                $metric.Filter | Should BeExactly $filter
                $metric.Description | Should BeNullOrEmpty
            }
        }
        finally {
            gcloud beta logging metrics delete $metricName --quiet 2>$null
        }
    }

    It "should work with -Description" {
        $r = Get-Random
        $metricName = "gcps-new-gclogmetric-$r"
        $logName = "gcps-new-gclogmetric-log-$r"
        $description = "This is a log metric"
        try {
            $createdMetric = New-GcLogMetric $metricName -LogName $logName -Description $description
            $onlineMetric = Get-GcLogMetric $metricName

            ForEach ($metric in @($createdMetric, $onlineMetric)) {
                $metric | Should Not BeNullOrEmpty
                $metric.Name | Should BeExactly $metricName
                $metric.Filter | Should BeExactly "logName = `"projects/$project/logs/$logName`""
                $metric.Description | Should BeExactly $description
            }
        }
        finally {
            gcloud beta logging metrics delete $metricName --quiet 2>$null
        }
    }

    It "should work with multiple parameters" {
        $r = Get-Random
        $metricName = "gcps-new-gclogmetric-$r"
        $metricNameTwo = "gcps-new-gclogmetric-2-$r"
        $logName = "gcps-new-gclogmetric-log-$r"
        $description = "This is a log metric"
        $after = [DateTime]::new(2017, 12, 12)
        $afterTimeString = "timestamp >= `"2017-12-12T00:00:00-08:00`""
        try {            
            $createdMetric = New-GcLogMetric $metricName -LogName $logName -Description $description -Severity INFO
            $onlineMetric = Get-GcLogMetric $metricName

            ForEach ($metric in @($createdMetric, $onlineMetric)) {
                $metric | Should Not BeNullOrEmpty
                $metric.Name | Should BeExactly $metricName
                $metric.Filter |
                    Should BeExactly "logName = `"projects/$project/logs/$logName`" AND severity = INFO"
                $metric.Description | Should BeExactly $description
            }

            $createdMetric = New-GcLogMetric $metricNameTwo -Description $description -Severity ERROR -After $after
            $onlineMetric = Get-GcLogMetric $metricNameTwo

            ForEach ($metric in @($createdMetric, $onlineMetric)) {
                $metric | Should Not BeNullOrEmpty
                $metric.Name | Should BeExactly $metricNameTwo
                $metric.Filter | Should BeExactly "severity = ERROR AND $afterTimeString"
                $metric.Description | Should BeExactly $description
            }
        }
        finally {
            gcloud beta logging metrics delete $metricName --quiet 2>$null
            gcloud beta logging metrics delete $metricNameTwo --quiet 2>$null
        }
    }

    It "should throw error for existing log metric" {
        $r = Get-Random
        $metricName = "gcps-new-gclogmetric-$r"
        $logName = "gcps-new-gclogmetric-log-$r"
        try {
            New-GcLogMetric $metricName -LogName $logName
            { New-GcLogMetric $metricName -LogName $logName -ErrorAction Stop } |
                Should Throw "already exists."
        }
        finally {
            gcloud beta logging metrics delete $metricName --quiet 2>$null
        }
    }

    It "should throw error if filter cannot be constructed" {
        $r = Get-Random
        $metricName = "gcps-new-gclogmetric-$r"
        $logName = "gcps-new-gclogmetric-log-$r"
        try {
            { New-GcLogMetric $metricName -ErrorAction Stop } |
                Should Throw "Cannot construct filter"
        }
        finally {
            gcloud beta logging metrics delete $metricName --quiet 2>$null
        }
    }
}

Describe "Remove-GcLogMetric" {
    It "should throw error for non-existent log metric" {
        { Remove-GcLogMetric -MetricName "non-existent-log-metric-powershell-testing" -ErrorAction Stop } |
            Should Throw "does not exist"
    }

    It "should work" {
        $r = Get-Random
        $metricName = "gcps-remove-gclogmetric-$r"
        New-GcLogMetric $metricName -Filter "This is a filter"
        Get-GcLogMetric -MetricName $metricName | Should Not BeNullOrEmpty

        Remove-GcLogMetric $metricName
        { Get-GcLogMetric -MetricName $metricName -ErrorAction Stop } | Should Throw "does not exist"
    }


    It "should work for multiple metrics" {
        $r = Get-Random
        $metricName = "gcps-remove-gclogmetric-$r"
        $metricNameTwo = "gcps-remove-gclogmetric-2-$r"
        New-GcLogMetric $metricName -Filter "This is a filter"
        New-GcLogMetric $metricNameTwo -Filter "This is a filter"
        Get-GcLogMetric -MetricName $metricName | Should Not BeNullOrEmpty
        Get-GcLogMetric -MetricName $metricNameTwo | Should Not BeNullOrEmpty

        Remove-GcLogMetric $metricName, $metricNameTwo
        { Get-GcLogMetric -MetricName $metricName -ErrorAction Stop } | Should Throw "does not exist"
        { Get-GcLogMetric -MetricName $metricNameTwo -ErrorAction Stop } | Should Throw "does not exist"
    }

    It "should work for log metric object" {
        $r = Get-Random
        $metricName = "gcps-remove-gclogmetric-$r"
        New-GcLogMetric $metricName -Filter "This is a filter"

        $createdMetricObject = Get-GcLogMetric -MetricName $metricName

        Remove-GcLogMetric $createdMetricObject
        { Get-GcLogMetric -MetricName $metricName -ErrorAction Stop } | Should Throw "does not exist"
    }

    It "should work with pipelining" {
        $r = Get-Random
        $metricName = "gcps-remove-gclogmetric-$r"
        $metricNameTwo = "gcps-remove-gclogmetric-2-$r"
        New-GcLogMetric $metricName -Filter "This is a filter"
        New-GcLogMetric $metricNameTwo -Filter "This is a filter"
        Get-GcLogMetric -MetricName $metricName | Should Not BeNullOrEmpty
        Get-GcLogMetric -MetricName $metricNameTwo | Should Not BeNullOrEmpty

        Get-GcLogMetric -MetricName $metricName, $metricNameTwo | Remove-GcLogMetric
        { Get-GcLogMetric -MetricName $metricName -ErrorAction Stop } | Should Throw "does not exist"
        { Get-GcLogMetric -MetricName $metricNameTwo -ErrorAction Stop } | Should Throw "does not exist"
    }
}
