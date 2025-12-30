import time
import xml.etree.ElementTree as ET
from datetime import date as date_type
from datetime import datetime
from email.utils import formatdate
from pathlib import Path
from typing import Dict, List, Optional

import htmlmin
import markdown
import markdown_katex  # noqa: F401
import typer
from markdown.extensions import Extension
from markdown.treeprocessors import Treeprocessor
from sqlalchemy import UniqueConstraint
from sqlmodel import Field, Relationship, Session, SQLModel, create_engine, select

app = typer.Typer()


# --- Database Models ---


class PostTagLink(SQLModel, table=True):
    __tablename__ = "post_tags"
    __table_args__ = (UniqueConstraint("post_id", "tag_id"),)
    post_id: Optional[int] = Field(
        default=None, foreign_key="posts.id", primary_key=True
    )
    tag_id: Optional[int] = Field(default=None, foreign_key="tags.id", primary_key=True)


class Tag(SQLModel, table=True):
    __tablename__ = "tags"
    id: Optional[int] = Field(default=None, primary_key=True)
    tag_name: str = Field(unique=True, index=True)

    posts: List["Post"] = Relationship(back_populates="tags", link_model=PostTagLink)


class Post(SQLModel, table=True):
    __tablename__ = "posts"
    id: Optional[int] = Field(default=None, primary_key=True)
    date: date_type
    title: str
    subtitle: str
    content: str
    show: bool = Field(default=True)
    slug: str = Field(unique=True, index=True)

    tags: List[Tag] = Relationship(back_populates="posts", link_model=PostTagLink)


# --- Markdown Extensions ---


class ImgUrlRewriter(Treeprocessor):
    def __init__(self, slug, md=None):
        super().__init__(md)
        self.slug = slug

    def run(self, root):
        for element in root.iter("img"):
            src = element.get("src")
            if src and not src.startswith(("/", "http://", "https://")):
                element.set("src", f"{self.slug}/{src}")


class ImgUrlExtension(Extension):
    def __init__(self, slug, **kwargs):
        self.slug = slug
        super().__init__(**kwargs)

    def extendMarkdown(self, md):
        md.treeprocessors.register(ImgUrlRewriter(self.slug, md), "img_rewriter", 15)


# --- RSS Builder ---


# monkey patching xml.etree.ElementTree
# https://stackoverflow.com/a/8915039
ET._original_serialize_xml = ET._serialize_xml


def _serialize_xml(write, elem, qnames, namespaces, short_empty_elements, **kwargs):
    if elem.tag == "![CDATA[":
        write("\n<%s%s]]>\n" % (elem.tag, elem.text))
        return
    return ET._original_serialize_xml(
        write, elem, qnames, namespaces, short_empty_elements=short_empty_elements
    )


ET._serialize_xml = ET._serialize["xml"] = _serialize_xml

LINK = "https://blog.msmetko.xyz/posts/{}"


def subelement(parent, tag, text):
    e = ET.SubElement(parent, tag)
    e.text = text
    return e


def CDATA(parent, tag, text):
    child = subelement(parent, tag, None)
    return subelement(child, "![CDATA[", text)


class RssBuilder:
    def __init__(self, post_list: List[Post]):
        self.build_date = formatdate().replace("-", "+")
        self.root = ET.Element(
            "rss",
            {
                "xmlns:dc": "http://purl.org/dc/elements/1.1/",
                "xmlns:content": "http://purl.org/rss/1.0/modules/content/",
                "xmlns:atom": "http://www.w3.org/2005/Atom",
                "xmlns:cc": "http://creativecommons.org/ns#",
            },
        )
        self.channel = ET.SubElement(self.root, "channel")
        subelement(self.channel, "title", "blog.msmetko.xyz")
        subelement(self.channel, "link", "https://blog.msmetko.xyz")
        subelement(
            self.channel,
            "description",
            "Marijan Smetko writes about programming, Python, math, physics, machine and deep learning, statistics, Linux, music...",
        )
        subelement(self.channel, "language", "en-us")
        subelement(self.channel, "generator", "msmetko")
        subelement(self.channel, "docs", "https://www.rssboard.org/rss-2-0-11")
        subelement(self.channel, "managingEditor", "msmetko@msmetko.xyz")
        ET.SubElement(
            self.channel,
            "atom:link",
            {
                "href": "https://blog.msmetko.xyz/feed",
                "rel": "self",
                "type": "application/rss+xml",
            },
        )
        subelement(self.channel, "webmaster", "msmetko@msmetko.xyz")
        subelement(self.channel, "copyright", "CC BY 4.0")

        for post in post_list:
            self.add_post(post)

    def write(self, filename):
        subelement(self.channel, "pubDate", self.build_date)
        subelement(self.channel, "lastBuildDate", self.build_date)
        ET.ElementTree(self.root).write(
            filename, encoding="UTF-8", xml_declaration=True
        )

    def add_post(self, post: Post):
        if post.show:
            item = ET.SubElement(self.channel, "item")
            CDATA(item, "title", post.title)
            CDATA(item, "description", post.subtitle)
            subelement(item, "link", LINK.format(post.slug))
            subelement(item, "author", "msmetko@msmetko.xyz")
            for tag in post.tags:
                CDATA(item, "category", tag.tag_name)

            # Handle date conversion for RSS
            # post.date is a date object (from SQLModel/Python)
            dt = datetime(post.date.year, post.date.month, post.date.day)
            subelement(
                item,
                "pubDate",
                formatdate(time.mktime(dt.timetuple())).replace("-", "+"),
            )
            subelement(item, "dc:creator", "Marijan Smetko")


# --- Main Logic ---


def process_blog_entry_dir(blog_dir: Path, tag_cache: Dict[str, Tag]) -> Post:
    if not blog_dir.is_dir():
        raise ValueError(f"{blog_dir} is not a directory")

    slug = blog_dir.name
    index_file = blog_dir / "index.md"
    if not index_file.exists():
        raise ValueError(f"index.md not found in {blog_dir}")

    content = index_file.read_text()
    md = markdown.Markdown(
        extensions=[
            ImgUrlExtension(slug=slug),
            "pymdownx.extra",
            "pymdownx.tilde",
            "markdown_katex",
            "full_yaml_metadata",
            "smarty",
            "sane_lists",
            "footnotes",
            "mdx_breakless_lists",
            "pymdownx.emoji",
            "toc",
            "codehilite",
            "markdown_captions",
            "attr_list",
        ],
        extension_configs=dict(
            codehilite={"css_class": "codehilite", "lineno": True},
            toc={"marker": "!!!TOC!!!"},
        ),
        output_format="html5",
    )
    t0 = time.perf_counter()
    html = md.convert(content)
    t1 = time.perf_counter()
    html = htmlmin.minify(html)
    t2 = time.perf_counter()

    typer.secho(
        f"[{slug}] Markdown: {t1 - t0:.4f}s, Minify: {t2 - t1:.4f}s",
        fg=typer.colors.CYAN,
    )

    metadata = md.Meta

    # Extract tags
    tag_names = metadata.get("tags", [])
    tag_objs = []
    for tag_name in tag_names:
        if tag_name not in tag_cache:
            tag_cache[tag_name] = Tag(tag_name=tag_name)
        tag_objs.append(tag_cache[tag_name])

    return Post(
        date=metadata.get("date"),
        title=metadata.get("title"),
        subtitle=metadata.get("subtitle"),
        content=html,
        show=metadata.get("show", True),
        slug=slug,
        tags=tag_objs,
    )


@app.command()
def main(files: List[Path]):
    db_path = Path("db.sqlite3")
    if db_path.exists():
        db_path.unlink()

    sqlite_url = f"sqlite:///{db_path}"
    engine = create_engine(sqlite_url)
    SQLModel.metadata.create_all(engine)

    tag_cache: Dict[str, Tag] = {}
    posts: List[Post] = []

    for blog_dir in files:
        try:
            post = process_blog_entry_dir(blog_dir, tag_cache)
            posts.append(post)
        except Exception as e:
            typer.echo(f"Error processing {blog_dir}: {e}", err=True)

    # Sort by date (oldest first)
    posts.sort(key=lambda p: p.date)

    t_db_start = time.perf_counter()
    with Session(engine) as session:
        for post in posts:
            session.add(post)
        session.commit()

        # Re-fetch posts sorted by date for RSS
        statement = select(Post).order_by(Post.date)
        posts_for_rss = session.exec(statement).all()

        # Generate RSS
        rss_builder = RssBuilder(posts_for_rss)
        rss_builder.write("feed.rss")
    t_db_end = time.perf_counter()
    typer.secho(
        f"Database & RSS: {t_db_end - t_db_start:.4f}s", fg=typer.colors.MAGENTA
    )


if __name__ == "__main__":
    app()
