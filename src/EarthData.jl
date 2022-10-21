module EarthData

# Write your package code here.
using LibCURL

netrcpath="/Users/steven/.netrc"
cookiefile="/Users/steven/.urs_cookies"

curl = curl_easy_init()
curl_easy_setopt(curl, CURLOPT, "hhtps://data.gesdisc.earthdata.nasa.gov/s3credentials")
curl_easy_setopt(curl, CURLOPT_NETRC, CURL_NETRC_REQUIRED)
curl_easy_setopt(curl, CURLOPT_NETRC_FILE, netrcpath)
curl_easy_setopt(curl, CURLOPT_COOKIEFILE, cookiefile)
curl_easy_setopt(curl, CURLOPT_COOKIEJAR, cookiefile)
curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1)

function curl_write_cb(curlbuf::Ptr{Cvoid}, s::Csize_t, p_ctxt::Ptr{Cvoid})::Csize_t
    sz = s * n
    data = Array{UInt8}(undef, sz)

    ccall(:memcpy, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}, UInt64), data, curlbuf, sz)

    if p_ctxt == C_NULL
        j_ctxt = nothing
    else
        j_ctxt = unsafe_pointer_to_objref(p_ctxt)
    end

    append!(j_ctxt, data)
end

end
