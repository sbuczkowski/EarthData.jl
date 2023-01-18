module EarthData

export earthdata_get_s3credentials, awscred

# Write your package code here.
using LibCURL
using JSON
using TimeZones
using AWS: AWSCredentials

function curl_write_cb(curlbuf::Ptr{Cvoid}, s::Csize_t, n::Csize_t, p_ctxt::Ptr{Cvoid})::Csize_t
    sz = s * n
    data = Array{UInt8}(undef, sz)
    
    ccall(:memcpy, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}, UInt64), data, curlbuf, sz)
    
    if p_ctxt == C_NULL
        j_ctxt = nothing
    else
        j_ctxt = unsafe_pointer_to_objref(p_ctxt)
    end
    
    append!(j_ctxt, data)
    return sz::Csize_t
end

# earthdata_get_s3credentials is caled with a valid AWSCredential struct which should
# be built off the user's .aws credential files with global_aws_config() prior to updating 
# with EarthData creds
function earthdata_get_s3credentials()::AWSCredentials

# Set user Earthdata login info locations
userhome = ENV["HOME"]
netrcpath=joinpath(userhome,".netrc")
cookiefile=joinpath(userhome,".urs_cookies")

# Set up curl options for the Earthdata web query
curl = curl_easy_init()
curl_easy_setopt(curl, CURLOPT_URL, "https://data.gesdisc.earthdata.nasa.gov/s3credentials")
curl_easy_setopt(curl, CURLOPT_NETRC, CURL_NETRC_REQUIRED)
curl_easy_setopt(curl, CURLOPT_NETRC_FILE, netrcpath)
curl_easy_setopt(curl, CURLOPT_COOKIEFILE, cookiefile)
curl_easy_setopt(curl, CURLOPT_COOKIEJAR, cookiefile)
curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1)

    c_curl_write_cb = @cfunction(curl_write_cb, Csize_t, (Ptr{Cvoid}, Csize_t, Csize_t, Ptr{Cvoid}))
curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, c_curl_write_cb)
buffer = UInt8[]
curl_easy_setopt(curl, CURLOPT_WRITEDATA, pointer_from_objref(buffer))

# post the query and fill buffer with the JSON data as a string
GC.@preserve buffer begin
    res = curl_easy_perform(curl)
end

# parse into formal JSON struct

    j = JSON.parse(String(buffer))

    # Replace AWSCredential fields as required with new values from EarthData
awscred = AWSCredentials()
    awscred.access_key_id = j["accessKeyId"]
awscred.secret_key = j["secretAccessKey"] 
awscred.expiry = DateTime(ZonedDateTime(j["expiration"], "yyyy-mm-dd HH:MM:SSzzzz"))
    awscred.token = j["sessionToken"]
    awscred.renew = earthdata_get_s3credentials

return awscred
end

end
