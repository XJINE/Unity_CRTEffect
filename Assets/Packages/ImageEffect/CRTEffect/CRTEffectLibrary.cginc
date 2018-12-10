#ifndef CRTEFFECT_LIBRARY_INCLUDED
#define CRTEFFECT_LIBRARY_INCLUDED

float CRTRandom(float2 texCoord, float seed)
{
    // NOTE:
    // Standard hlsl random.
    return frac(sin(dot(texCoord.xy, float2(12.9898, 78.233)) + seed) * 43758.5453);
}

float2 GetBarrelDistortedCoord(float2 texCoord, float k1, float k2)
{
    // NOTE:
    // k1, k2 means strength. 
    // Popular values are k1:0.2 k2:0.01.

    float2 distortedCoord;
    float2 centerOriginCoord = texCoord - 0.5;

    float rr = centerOriginCoord.x * centerOriginCoord.x
             + centerOriginCoord.y * centerOriginCoord.y;
    float rrrr = rr * rr;
    float distortion = 1 + k1 * rr + k2 * rrrr;

    distortedCoord = centerOriginCoord * distortion;
    distortedCoord += 0.5;

    // CAUTION:
    // Somtimes return under 0 or over 1 value.

    return distortedCoord;
}

float4 GetGlassSpecular(float2 texCoord, float2 distortedCoord, float4 light)
{
    float3 eyePos = float3(0, 0, 2);

    // STEP:1
    // Get fake normal from distortedCoord.

    float xDistRatio = texCoord.x - distortedCoord.x;
    float yDistRatio = texCoord.y - distortedCoord.y;

    float3 normal = normalize(float3(xDistRatio, yDistRatio, 1));

    // STEP:2
    // Get fake pixel coord in 3D.
    // The coord's origin is center of the image.
    // The maximum value of z coord must be 1.

    float3 pixelPos = float3(distortedCoord.x - 0.5f,
                             distortedCoord.y - 0.5f,
                             1 - (abs(xDistRatio) + abs(yDistRatio)));

    // Debug color.
    // return float4(pixelPos.x + 0.5f, pixelPos.y + 0.5f, pixelPos.z, 1);

    // STEP:3
    // Shading.

    float  Ks   = 0.8f; // Material parameter.
    float3 view = normalize(eyePos - pixelPos);
    float3 hlf  = normalize(light.xyz - pixelPos + view);

    return pow(dot(normal, hlf), light.w) * Ks;
}

float4 GetShadowMaskColor(sampler2D tex, float2 texCoord, float2 texSize, float2 texelSize)
{
    int column = round(texCoord.x * texSize.x + 0.5) % 3;
    int row    = round(texCoord.y * texSize.y + 0.5);

    bool evenRow = row % 2 == 0;

    texCoord.x += evenRow ? lerp(0, texelSize.x, column) : max(0, column - 1) * texelSize.x;
    
    float4 color = tex2D(tex, texCoord);

    color.r = evenRow ? lerp(color.r, 0, column) : lerp(0, color.r, column - 1);
    color.g = evenRow ? column % 2 * color.g : lerp(color.g, 0, column);
    color.b = evenRow ? lerp(0, color.b, column - 1) : column % 2 * color.b;

    return color;

    // NOTE:
    // In even row,
    // - 0 column : current pixel R.
    // - 1 column : next pixel G.
    // - 2 column : next pixel B.
    // In odd row,
    // - 0 column : current pixel G.
    // - 1 column : current pixel B.
    // - 2 column : next pixel R.

    // NOTE:
    // These code are same as following code.
    // 
    //if (row % 2 == 0)
    //{
    //    if (column == 0)
    //    {
    //        color = tex2D(image, texCoord);
    //        color.gb = 0;
    //    }
    //    else if (column == 1)
    //    {
    //        texCoord.x += texelSize.x;
    //        color = tex2D(image, texCoord);
    //        color.rb = 0;
    //    }
    //    else if (column == 2)
    //    {
    //        texCoord.x += texelSize.x;
    //        color = tex2D(image, texCoord);
    //        color.rg = 0;
    //    }
    //}
    // 
    //else
    //{
    //    if (column == 0)
    //    {
    //        color = tex2D(image, texCoord);
    //        color.rb = 0;
    //    }
    //    if (column == 1)
    //    {
    //        color = tex2D(image, texCoord);
    //        color.rg = 0;
    //    }
    //    if (column == 2)
    //    {
    //        texCoord.x += pixelSize.x;
    //        color = tex2D(image, texCoord);
    //        color.bg = 0;
    //    }
    //}
}

float4 GetApertureGrillColor(sampler2D tex, float2 texCoord, float2 texSize, float2 texelSize)
{
    int column = round(texCoord.x * texSize.x + 0.5) % 3;

    float4 color = tex2D(tex, texCoord);

    color.r = lerp(color.r, 0, column);
    color.g = column % 2 * color.g;
    color.b = lerp(0, color.b, column - 1);

    return color;

    // NOTE:
    // These code are same as following code.
    // 
    //if (column == 0)
    //{
    //    color.gb = 0;
    //}
    //else if (column == 1)
    //{
    //    color.rb = 0;
    //}
    //else
    //{
    //    color.rg = 0;
    //}
}

float4 GetCornerShadowPower(float2 texCoord, float strength)
{
    // NOTE:
    // CRT does not shows clear color in the corner.
    // This is like a vignette effect.

    float2 centerOriginCoord  = texCoord - 0.5f;
    float  distanceFromCenter = sqrt(centerOriginCoord.x * centerOriginCoord.x
                                    + centerOriginCoord.y * centerOriginCoord.y);

    return saturate(1 - distanceFromCenter * distanceFromCenter * strength);
}

#endif