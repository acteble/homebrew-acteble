BeforeAll { . "$PSScriptRoot/../install.ps1" }

Describe 'Select-ActebleRelease' {
    BeforeAll {
        $script:list = @(
            [pscustomobject]@{ tag_name = 'v2.0.0-beta.3'; prerelease = $true },
            [pscustomobject]@{ tag_name = 'v1.9.0'; prerelease = $false },
            [pscustomobject]@{ tag_name = 'v2.0.0-beta.2'; prerelease = $true }
        )
    }
    It 'beta picks the newest prerelease' {
        (Select-ActebleRelease -Releases $list -Beta).tag_name | Should -Be 'v2.0.0-beta.3'
    }
    It 'stable picks the newest non-prerelease' {
        (Select-ActebleRelease -Releases $list).tag_name | Should -Be 'v1.9.0'
    }
    It 'beta throws when no prerelease exists' {
        { Select-ActebleRelease -Releases @($list[1]) -Beta } | Should -Throw '*no beta release*'
    }
    It 'stable throws when only prereleases exist' {
        { Select-ActebleRelease -Releases @($list[0]) } | Should -Throw '*no stable release*'
    }
}

Describe 'usage' {
    It 'documents -Beta' {
        Get-ActebleUsage | Should -Match '-Beta'
    }
}
