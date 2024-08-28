$pwd = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesUnderTest = "$((Get-Item $pwd).Parent.Parent.FullName)\src\main\scripts\modules\"
$moduleMockMethod = "$((Get-Item $pwd).Parent.Parent.FullName)\test\resources\mocked.modules"

if(-not $env:PsModulePath.Contains($modulesUnderTest)) {
    $env:PSModulePath = $env:PSModulePath + ";$($modulesUnderTest)"
}

if(-not $env:PsModulePath.Contains($moduleMockMethod)) {
    $env:PSModulePath = $env:PSModulePath + ";$($moduleMockMethod)"
}

Import-Module Logger
Import-Module  NfsShareConfig


$params = @{nfsShareLogDir="C:\NetAnServer\test\module.test\NfaShareConfig.Tests.ps1"}

Describe "Test NfsShareConfig.tests.psm1 Unit Test" {

    Context "When Install-NFS is called" {
        Mock -ModuleName Logger Log-Message {}
        
        It "Test Install-NFS when all methods return true" {
            Mock -ModuleName NfsShareConfig Test-Path {  $true}
            Mock -ModuleName NfsShareConfig Test-ServiceExists  {return $true }
            Mock -ModuleName NfsShareConfig Check-TasksInTaskScheduler { return $true }
            Mock -ModuleName NfsShareConfig Invoke-command {  return $true }
            
            $check = Install-NFS $params
            $check | Should Be $True
            Assert-MockCalled Test-Path -ModuleName NfsShareConfig -Exactly 1 -Scope It
            Assert-MockCalled Test-ServiceExists -ModuleName NfsShareConfig -Exactly 1 -Scope It
            Assert-MockCalled Check-TasksInTaskScheduler -ModuleName NfsShareConfig -Exactly 1 -Scope It
            Assert-MockCalled Invoke-command -ModuleName NfsShareConfig -Exactly 2 -Scope It
        }

        It "Test Install-NFS when invoke failed" {
            Mock -ModuleName NfsShareConfig Test-Path {  $true}
            Mock -ModuleName NfsShareConfig Test-ServiceExists  {return $false }
            Mock -ModuleName NfsShareConfig Invoke-command {  throw}
            
            $check = Install-NFS $params
            $check | Should Be $false
            Assert-MockCalled Invoke-command -ModuleName NfsShareConfig -Exactly 1 -Scope It
            
        }

        It "Test Install-NFS when Check-TasksInTaskScheduler return false but Add-TasksInTaskScheduler true" {
            Mock -ModuleName NfsShareConfig Test-Path {  $true}
            Mock -ModuleName NfsShareConfig Test-ServiceExists  {return $true }
            Mock -ModuleName NfsShareConfig Check-TasksInTaskScheduler { return $false }
            Mock -ModuleName NfsShareConfig Add-TasksInTaskScheduler { return $true}
            Mock -ModuleName NfsShareConfig Invoke-command {  return $true }
            
            $check = Install-NFS $params
            $check | Should Be $True
        }

         It "Test Install-NFS when both Check-TasksInTaskScheduler and Add-TasksInTaskScheduler return false" {
            Mock -ModuleName NfsShareConfig Test-Path {  $true}
            Mock -ModuleName NfsShareConfig Test-ServiceExists  {return $true }
            Mock -ModuleName NfsShareConfig Check-TasksInTaskScheduler { return $false }
            Mock -ModuleName NfsShareConfig Add-TasksInTaskScheduler { return $false}
            Mock -ModuleName NfsShareConfig Invoke-command {  return $true }
            
            $check = Install-NFS $params
            $check | Should Be $false
        }

        It "Test Install-NFS when Test-path failed " {
            Mock -ModuleName NfsShareConfig Test-Path {  $false}
            Mock -ModuleName NfsShareConfig New-Item { throw }      
            $check = Install-NFS $params
            $check | Should Be $false
            
        }
        It "Test Install-NFS when Test-ServiceExists failed " {
            Mock -ModuleName NfsShareConfig Test-Path {  $true}
            Mock -ModuleName NfsShareConfig Test-ServiceExists  { return $false }     
           
            $check = Install-NFS $params
            $check | Should Be $false
            
        }
    }

    Context "When Add-TasksInTaskScheduler is called" {

        Mock -ModuleName Logger Log-Message {}
        It "Test Add-TasksInTaskScheduler when Invoke-command pass " {
            Mock -ModuleName NfsShareConfig Invoke-command {  return $true }    
            $check = Add-TasksInTaskScheduler $params
            $check | Should Be $True
            Assert-MockCalled Invoke-command -ModuleName NfsShareConfig -Exactly 1 -Scope It
        }
        It "Test Add-TasksInTaskScheduler when Invoke-command failed " {
            Mock -ModuleName NfsShareConfig Invoke-command { throw }    
            $check = Add-TasksInTaskScheduler $params
            $check | Should Be $false
            Assert-MockCalled Invoke-command -ModuleName NfsShareConfig -Exactly 1 -Scope It
        }
    }
}
