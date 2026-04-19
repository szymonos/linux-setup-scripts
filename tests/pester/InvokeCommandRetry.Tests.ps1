#Requires -Modules Pester
# Unit tests for Invoke-CommandRetry in InstallUtils module

BeforeAll {
    . $PSScriptRoot/../../modules/InstallUtils/Functions/common.ps1
}

Describe 'Invoke-CommandRetry' {
    It 'succeeds on first attempt' {
        $Script:retryCounter = 0
        Invoke-CommandRetry -Command { $Script:retryCounter++ } -MaxRetries 3
        $Script:retryCounter | Should -Be 1
    }

    It 'stops after MaxRetries on persistent error' {
        $Script:retryCounter = 0
        Invoke-CommandRetry -Command {
            $Script:retryCounter++
            $ex = [System.IO.IOException]::new('persistent error')
            throw $ex
        } -MaxRetries 3 -ErrorAction SilentlyContinue -Verbose:$false
        $Script:retryCounter | Should -BeLessOrEqual 3
    }

    It 'rethrows non-retryable exceptions' {
        {
            Invoke-CommandRetry -Command {
                throw [InvalidOperationException]::new('bad')
            } -MaxRetries 2 -ErrorAction Stop
        } | Should -Throw
    }

    It 'executes command successfully when no error' {
        $Script:retryResult = $null
        Invoke-CommandRetry -Command { $Script:retryResult = 'success' }
        $Script:retryResult | Should -Be 'success'
    }
}
