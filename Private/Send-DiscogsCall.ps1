<#
    .SYNOPSIS
        Sends a call off to Discogs API
    .DESCRIPTION
        Send a pre-packaged Discogs call off to the API.
    .EXAMPLE
        PS C:\> Send-DiscogsCall -Method 'Get' -Uri 'https://api.Discogs.com/users/myusername/lists' -token 'abcdef1234567890'
        Uses the supplied token and passes Get and the Uri to invoke-webrequest and returns it while handling errors
    .PARAMETER Method
        Specifies the HTTP request method (usually Get, Put, Post, Delete)        
    .PARAMETER Uri
        Specifies the URI of the internet ressource. Example: https://api.Discogs.com/users/myusername/lists
    .PARAMETER Body
        [optional] Specifies the Body of the request to send
    .PARAMETER Token
        [Optional] specifies the token to use for authentication.
#>
function Send-DiscogsCall {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string]$Method,
        [Parameter(Mandatory)][string]$Uri,
        $Body,
        [string]$Token
    )
    $AgentString = "VinylSommelier/0.1.0"

    # Prepare header
    if ($token)
    {
        if ($url.IndexOf('\?') -ge 0) 
        {
            $uriWithToken = "$uri&token=$token"
        }
        else {
            $uriWithToken = "$uri`?token=$token"
        }
    }

    Write-Verbose 'Attempting to send request to API'
    $originalProgressPreference = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'
    try {

        $Response = Invoke-WebRequest -Method $Method -Body $Body -Uri $UriWithToken -UserAgent $AgentString
        $results = $($Response.content | convertFrom-json).releases
        while ( ($response.content | convertFrom-json).pagination.page -ne ($response.content | convertFrom-json).pagination.pages )
        {
            $Response = Invoke-WebRequest -Method $Method -Body $Body -Uri ($response.content | convertFrom-json).pagination.urls.next -UserAgent $AgentString
            $results+= $($Response.content | convertFrom-json).releases
        }
    }
    catch {
        # if we hit the rate limit of Discogs API, code is 429
        if ($_.Exception.Response.StatusCode -eq 429) {
            $WaitTime = 5
            Write-Warning "API Rate Limit reached, Discogs limits to 60 per minute.  Waiting $WaitTime seconds"

            # wait number of seconds indicated by Discogs
            Start-Sleep -Seconds $WaitTime 

            # then make request again (no try catch this time)
            $Response = Invoke-WebRequest -Method $Method -Body $Body -Uri $UriWithToken -UserAgent $AgentString
            $results = $($Response.content | convertFrom-json).releases
            while ( ($response.content | convertFrom-json).pagination.page -ne ($response.content | convertFrom-json).pagination.pages )
            {
                $Response = Invoke-WebRequest -Method $Method -Body $Body -Uri ($response.content | convertFrom-json).pagination.urls.next -UserAgent $AgentString
                $results+= $($Response.content | convertFrom-json).releases
            }
        }
        else {
            # Exception is not Rate Limit so throw it
            Throw $PSItem
        }
    }
    $ProgressPreference = $originalProgressPreference

    Write-Verbose 'We got API response'
    return $results
}