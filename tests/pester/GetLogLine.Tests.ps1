#Requires -Modules Pester
# Unit tests for Get-LogLine in do-common module

BeforeAll {
    . $PSScriptRoot/../../modules/do-common/Functions/logs.ps1
}

Describe 'Get-LogLine' {
    BeforeAll {
        $Script:testContext = [PSCustomObject]@{
            TimeStamp  = [datetime]::new(2025, 6, 15, 10, 30, 45, 123)
            Invocation = 'test.ps1:42'
            Function   = 'Test-Function():10'
            IsVerbose  = $false
            IsDebug    = $false
        }
    }

    Context 'Show line type' {
        It 'contains timestamp, level, invocation, and function' {
            $result = Get-LogLine -LogContext $Script:testContext -Message 'hello world' -Level 'INFO' -LineType 'Show'
            $result | Should -Match '2025-06-15 10:30:45'
            $result | Should -Match 'INFO'
            $result | Should -Match 'test\.ps1:42'
            $result | Should -Match 'hello world'
        }

        It 'applies correct color for ERROR level' {
            $result = Get-LogLine -LogContext $Script:testContext -Message 'fail' -Level 'ERROR' -LineType 'Show'
            $result | Should -Match '91m.*ERROR'
        }

        It 'applies correct color for WARNING level' {
            $result = Get-LogLine -LogContext $Script:testContext -Message 'warn' -Level 'WARNING' -LineType 'Show'
            $result | Should -Match '93m.*WARNING'
        }

        It 'applies correct color for VERBOSE level' {
            $result = Get-LogLine -LogContext $Script:testContext -Message 'info' -Level 'VERBOSE' -LineType 'Show'
            $result | Should -Match '96m.*VERBOSE'
        }

        It 'applies correct color for DEBUG level' {
            $result = Get-LogLine -LogContext $Script:testContext -Message 'dbg' -Level 'DEBUG' -LineType 'Show'
            $result | Should -Match '35m.*DEBUG'
        }
    }

    Context 'Write line type' {
        It 'produces pipe-delimited plain text' {
            $result = Get-LogLine -LogContext $Script:testContext -Message 'log entry' -Level 'INFO' -LineType 'Write'
            $parts = $result.Split('|')
            $parts | Should -HaveCount 5
            $parts[0] | Should -Match '2025-06-15 10:30:45\.123'
            $parts[1] | Should -Be 'INFO'
            $parts[2] | Should -Be 'test.ps1:42'
            $parts[3] | Should -Be 'Test-Function():10'
            $parts[4] | Should -Be 'log entry'
        }
    }

    Context 'LogContext parameter is used correctly' {
        It 'works without $ctx in caller scope' {
            # Verify that Get-LogLine uses the $LogContext parameter directly
            # and does not depend on $ctx being in the caller scope.
            Remove-Variable -Name ctx -ErrorAction SilentlyContinue
            $result = Get-LogLine -LogContext $Script:testContext -Message 'test' -Level 'INFO' -LineType 'Write'
            $result | Should -Match 'INFO'
        }
    }
}
