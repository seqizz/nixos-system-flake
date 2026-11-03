<?xml version="1.0" encoding="UTF-8"?>
<!--
  Turns nginx's `autoindex_format xml` output into a thumbnail grid.

  nginx emits entries as <directory>/<file> elements whose *text* is the name,
  with mtime/size as attributes. Styling is inlined rather than served from a
  second location block so the whole feature is one file with no cache busting
  to get wrong.

  Driven by three xslt_string_param values set in the location block:
    uri   - $uri of the current request, always ends in '/'
    base  - the location prefix, used to hide the parent link at the top level
    title - heading and <title>
-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" encoding="utf-8" indent="no" />

<xsl:param name="uri" />
<xsl:param name="base" />
<xsl:param name="title" />

<xsl:variable name="upper" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'" />
<xsl:variable name="lower" select="'abcdefghijklmnopqrstuvwxyz'" />
<xsl:variable name="here" select="substring-after($uri, $base)" />

<!--
  Names come out of nginx unescaped, so anything with a space, '#' or '?' would
  produce a broken href. XSLT 1.0 has no url-encode, hence the char-by-char
  recursion over the bytes that actually break a relative link.
-->
<xsl:template name="urlencode">
  <xsl:param name="s" />
  <xsl:if test="string-length($s) &gt; 0">
    <xsl:variable name="c" select="substring($s, 1, 1)" />
    <xsl:choose>
      <xsl:when test="$c = '%'">%25</xsl:when>
      <xsl:when test="$c = '#'">%23</xsl:when>
      <xsl:when test="$c = '?'">%3F</xsl:when>
      <xsl:when test="$c = '&amp;'">%26</xsl:when>
      <xsl:when test="$c = '+'">%2B</xsl:when>
      <xsl:when test="$c = ' '">%20</xsl:when>
      <xsl:otherwise><xsl:value-of select="$c" /></xsl:otherwise>
    </xsl:choose>
    <xsl:call-template name="urlencode">
      <xsl:with-param name="s" select="substring($s, 2)" />
    </xsl:call-template>
  </xsl:if>
</xsl:template>

<xsl:template match="/">
  <xsl:text disable-output-escaping="yes">&lt;!DOCTYPE html&gt;</xsl:text>
  <html lang="en">
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <meta name="robots" content="noindex, nofollow" />
      <title><xsl:value-of select="$title" /><xsl:text> </xsl:text><xsl:value-of select="$here" /></title>
      <style>
        :root { color-scheme: dark; --bg:#16181d; --fg:#d7dae0; --dim:#8b92a0; --card:#1e2128; --line:#2c313a; --accent:#7aa2f7; }
        * { box-sizing: border-box; }
        body { margin:0; padding:1rem; background:var(--bg); color:var(--fg);
               font:14px/1.45 ui-sans-serif, system-ui, "DejaVu Sans", sans-serif; }
        h1 { margin:0 0 1rem; font-size:1.1rem; font-weight:600; }
        h1 span { color:var(--dim); font-weight:400; word-break:break-all; }
        a { color:var(--accent); text-decoration:none; }
        .dirs { display:flex; flex-wrap:wrap; gap:.4rem; margin-bottom:1rem; }
        .dirs a { padding:.3rem .7rem; background:var(--card); border:1px solid var(--line);
                  border-radius:5px; word-break:break-all; }
        .dirs a:hover { border-color:var(--accent); }
        .grid { display:grid; gap:.6rem;
                grid-template-columns:repeat(auto-fill, minmax(140px, 1fr)); }
        figure { margin:0; background:var(--card); border:1px solid var(--line);
                 border-radius:6px; overflow:hidden; }
        figure:hover { border-color:var(--accent); }
        .thumb { display:flex; align-items:center; justify-content:center;
                 height:140px; padding:.4rem; background:#0f1115; }
        /* contain, not cover: emoji and stickers must not get cropped */
        .thumb img, .thumb video { max-width:100%; max-height:100%; object-fit:contain; }
        .thumb.plain { color:var(--dim); font-size:1.6rem; }
        figcaption { padding:.4rem .5rem; font-size:11px; color:var(--dim);
                     word-break:break-all; border-top:1px solid var(--line); }
        /* :target turns the grid into a lightbox without any JavaScript */
        .lb { position:fixed; inset:0; background:#000d; display:none;
              align-items:center; justify-content:center; padding:2rem; z-index:10; }
        .lb:target { display:flex; }
        .lb img, .lb video { max-width:100%; max-height:100%; }
        .empty { color:var(--dim); }
      </style>
    </head>
    <body>
      <h1><xsl:value-of select="$title" /><xsl:text> </xsl:text><span>/<xsl:value-of select="$here" /></span></h1>

      <xsl:if test="$here != '' or count(list/directory) &gt; 0">
        <div class="dirs">
          <xsl:if test="$here != ''"><a href="../">..</a></xsl:if>
          <xsl:for-each select="list/directory">
            <xsl:variable name="href">
              <xsl:call-template name="urlencode"><xsl:with-param name="s" select="." /></xsl:call-template>
            </xsl:variable>
            <a href="{$href}/"><xsl:value-of select="." />/</a>
          </xsl:for-each>
        </div>
      </xsl:if>

      <xsl:choose>
        <xsl:when test="count(list/file) &gt; 0">
          <div class="grid">
            <xsl:for-each select="list/file">
              <xsl:variable name="href">
                <xsl:call-template name="urlencode"><xsl:with-param name="s" select="." /></xsl:call-template>
              </xsl:variable>
              <!-- extension match on both lengths, there is no regex in XSLT 1.0 -->
              <xsl:variable name="e4" select="translate(substring(., string-length() - 3), $upper, $lower)" />
              <xsl:variable name="e5" select="translate(substring(., string-length() - 4), $upper, $lower)" />
              <xsl:variable name="isImage"
                select="contains(' .jpg .png .gif .svg .bmp ', concat(' ', $e4, ' '))
                        or contains(' .jpeg .webp .avif ', concat(' ', $e5, ' '))" />
              <xsl:variable name="isVideo"
                select="contains(' .mp4 .mkv .mov .ogv ', concat(' ', $e4, ' '))
                        or contains(' .webm ', concat(' ', $e5, ' '))" />
              <figure>
                <xsl:choose>
                  <xsl:when test="$isImage">
                    <a class="thumb" href="#lb{position()}">
                      <img src="{$href}" alt="{.}" loading="lazy" />
                    </a>
                    <div class="lb" id="lb{position()}">
                      <a href="#"><img src="{$href}" alt="{.}" /></a>
                    </div>
                  </xsl:when>
                  <xsl:when test="$isVideo">
                    <!-- metadata only, a reaction folder can hold hundreds of clips -->
                    <div class="thumb">
                      <video src="{$href}" controls="controls" loop="loop" muted="muted"
                             playsinline="playsinline" preload="metadata" />
                    </div>
                  </xsl:when>
                  <xsl:otherwise>
                    <a class="thumb plain" href="{$href}">&#128196;</a>
                  </xsl:otherwise>
                </xsl:choose>
                <figcaption>
                  <a href="{$href}"><xsl:value-of select="." /></a>
                </figcaption>
              </figure>
            </xsl:for-each>
          </div>
        </xsl:when>
        <xsl:otherwise>
          <p class="empty">No files here.</p>
        </xsl:otherwise>
      </xsl:choose>
    </body>
  </html>
</xsl:template>
</xsl:stylesheet>
