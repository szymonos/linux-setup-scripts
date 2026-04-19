#Requires -Modules Pester
# Unit tests for ConvertFrom-Cfg and ConvertTo-Cfg in SetupUtils module

BeforeAll {
    . $PSScriptRoot/../../modules/SetupUtils/Functions/common.ps1
}

Describe 'ConvertFrom-Cfg' {
    It 'parses section with key-value pairs' {
        $input = @(
            '[section1]'
            'key1 = value1'
            'key2 = value2'
        )
        $result = $input | ConvertFrom-Cfg
        $result['section1']['key1'] | Should -Be 'value1'
        $result['section1']['key2'] | Should -Be 'value2'
    }

    It 'parses multiple sections' {
        $input = @(
            '[section1]'
            'key1 = value1'
            '[section2]'
            'key2 = value2'
        )
        $result = $input | ConvertFrom-Cfg
        $result.Keys | Should -HaveCount 2
        $result['section1']['key1'] | Should -Be 'value1'
        $result['section2']['key2'] | Should -Be 'value2'
    }

    It 'preserves header comments in __header__ key' {
        $input = @(
            '# This is a header comment'
            '# Another header line'
            '[section1]'
            'key = value'
        )
        $result = $input | ConvertFrom-Cfg
        $result.Contains('__header__') | Should -BeTrue
        $result['__header__'] | Should -BeLike '*header comment*'
    }

    It 'preserves comments within sections' {
        $input = @(
            '[section1]'
            '# inline comment'
            'key = value'
        )
        $result = $input | ConvertFrom-Cfg
        $result['section1']['Comment1'] | Should -Be '# inline comment'
        $result['section1']['key'] | Should -Be 'value'
    }

    It 'ignores non-comment lines before first section' {
        $input = @(
            'stray line without section'
            '[section1]'
            'key = value'
        )
        $result = $input | ConvertFrom-Cfg
        $result['section1']['key'] | Should -Be 'value'
        $result.Contains('__header__') | Should -BeFalse
    }

    It 'handles empty value' {
        $input = @(
            '[section1]'
            'key ='
        )
        $result = $input | ConvertFrom-Cfg
        $result['section1']['key'] | Should -Be ''
    }

    It 'trims whitespace from values' {
        $input = @(
            '[section1]'
            'key =   spaced value   '
        )
        $result = $input | ConvertFrom-Cfg
        $result['section1']['key'] | Should -Be 'spaced value'
    }

    It 'handles semicolon comments' {
        $input = @(
            '[section1]'
            '; semicolon comment'
            'key = value'
        )
        $result = $input | ConvertFrom-Cfg
        $result['section1']['Comment1'] | Should -Be '; semicolon comment'
    }

    It 'resets comment counter per section' {
        $input = @(
            '[section1]'
            '# comment in s1'
            '[section2]'
            '# comment in s2'
        )
        $result = $input | ConvertFrom-Cfg
        $result['section1']['Comment1'] | Should -Be '# comment in s1'
        $result['section2']['Comment1'] | Should -Be '# comment in s2'
    }

    It 'returns empty dict for empty input' {
        $result = @() | ConvertFrom-Cfg
        $result.Keys | Should -HaveCount 0
    }
}

Describe 'ConvertTo-Cfg' {
    It 'serializes ordered dictionary to cfg string' {
        $dict = [ordered]@{
            section1 = [ordered]@{
                key1 = 'value1'
                key2 = 'value2'
            }
        }
        $result = $dict | ConvertTo-Cfg
        $result | Should -Match '\[section1\]'
        $result | Should -Match 'key1 = value1'
        $result | Should -Match 'key2 = value2'
    }

    It 'restores header comments' {
        $dict = [ordered]@{
            '__header__' = '# header line'
            section1     = [ordered]@{ key = 'value' }
        }
        $result = $dict | ConvertTo-Cfg
        $result | Should -Match '# header line'
    }

    It 'serializes comment keys back as comments' {
        $dict = [ordered]@{
            section1 = [ordered]@{
                Comment1 = '# a comment'
                key      = 'value'
            }
        }
        $result = $dict | ConvertTo-Cfg
        $result | Should -Match '# a comment'
        $result | Should -Not -Match 'Comment1'
    }

    It 'handles LineFeed switch' {
        $dict = [ordered]@{
            section1 = [ordered]@{ key = 'value' }
        }
        $result = $dict | ConvertTo-Cfg -LineFeed
        $result | Should -Not -Match "`r`n"
    }
}

Describe 'ConvertFrom-Cfg / ConvertTo-Cfg roundtrip' {
    It 'preserves content through roundtrip' {
        $original = @(
            '# file header'
            '[core]'
            'autocrlf = true'
            '# a comment'
            'editor = vim'
            '[remote "origin"]'
            'url = https://github.com/foo/bar.git'
        )
        $parsed = $original | ConvertFrom-Cfg
        $serialized = $parsed | ConvertTo-Cfg -LineFeed

        # re-parse
        $reparsed = $serialized.Split("`n") | ConvertFrom-Cfg
        $reparsed['core']['autocrlf'] | Should -Be 'true'
        $reparsed['core']['editor'] | Should -Be 'vim'
        $reparsed['remote "origin"']['url'] | Should -Be 'https://github.com/foo/bar.git'
    }
}
