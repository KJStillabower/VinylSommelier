$key=Get-Content DiscogsApi.key
$BaseURI = "https://api.discogs.com/"



if ($null -eq (Get-Module -ListAvailable Spotishell))
{
    Write-Warning "You don't have Spotishell library"
    Write-Host "Try: Install-Module -Name Spotishell"
}

$RestResult = Invoke-RestMethod -uri "$baseURI/users/$username/collection/folders/0/releases?token=$key" -UserAgent $AgentString -method Get 
$results = $RestResult.releases
while ( $restResult.pagination.page -ne $restResult.pagination.pages )
{
    $RestResult = Invoke-RestMethod -uri "$($restresult.pagination.urls.next)" -UserAgent $AgentString -method Get 
    $results+= $RestResult.releases
}
Write-Host "Loaded $($results.count) releases)"


$wanted = Invoke-WebRequest -UserAgent $AgentString -uri "$BaseURI/users/$username/wants"



#region Spotify



New-SpotifyApplication -name "VinylSommelier" -ClientId $spotify.ClientID -ClientSecret $spotify.ClientSecret
Initialize-SpotifyApplication -ApplicationName "VinylSommelier"

$stats =@{  multiple = 0
            noutfound = 0
            found = 0
            Added = 0}
foreach ($entry in $results )
{
    $release = $entry.basic_Information
    

    $album = (Search-item -Query "album:""$($release.title)""artist:""$($release.artists[0].name)""" -Type "Album").albums
    if ($album.items.count -gt 1)
    {
        Write-Warning "Album: ""$($release.title)"" by:$($release.artists[0].name) found $($album.items.count) results!"
        foreach ($item in $album.items)
        {
            write-host "   $($item.name) - $($item.artists[0].name)"
        }
        $stats.multiple++;
    }
    elseif ($album.items.count -ne 1) {
        Write-Host "Album: ""$($release.title)"" by:$($release.artists[0].name) Not Found!" -ForegroundColor Red
        $stats.noutfound++;
    }
    else {
        if (! (Test-CurrentUserSavedAlbum -id $album.items.id))
        {
            Add-CurrentUserSavedAlbum -id $album.items.id
            Write-Host "Added: ""$($release.title)"" by: $($release.artists[0].name)"
            $stats.added ++;
        }
        else 
        {
            Write-Host "Added: ""$($release.title)"" by: $($release.artists[0].name) already exists." -ForegroundColor Green
        }
        $stats.found ++;
    }
}
$stats

#endregion


