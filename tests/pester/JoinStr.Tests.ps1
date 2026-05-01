#Requires -Modules Pester
# Unit tests for Join-Str in InstallUtils module

BeforeAll {
    . $PSScriptRoot/../../modules/InstallUtils/Functions/common.ps1
}

Describe 'Join-Str' {
    It 'wraps with single quotes' {
        $result = 'a', 'b' | Join-Str -SingleQuote
        $result | Should -Be "'a' 'b'"
    }

    It 'wraps with double quotes' {
        $result = 'a', 'b' | Join-Str -DoubleQuote
        $result | Should -Be '"a" "b"'
    }

    It 'combines separator and single quotes' {
        $result = 'x', 'y' | Join-Str -Separator ',' -SingleQuote
        $result | Should -Be "'x','y'"
    }

    It 'combines separator and double quotes' {
        $result = 'x', 'y' | Join-Str -Separator ',' -DoubleQuote
        $result | Should -Be '"x","y"'
    }

    It 'handles single item with single quote' {
        $result = 'only' | Join-Str -SingleQuote
        $result | Should -Be "'only'"
    }

    It 'handles pipeline array with single quote' {
        $result = @('one', 'two', 'three') | Join-Str -Separator '-' -SingleQuote
        $result | Should -Be "'one'-'two'-'three'"
    }

    It 'joins without quotes when neither switch is specified' {
        $result = 'a', 'b' | Join-Str
        $result | Should -Be 'a b'
    }
}
