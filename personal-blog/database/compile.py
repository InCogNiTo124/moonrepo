#!/usr/bin/env python3

import argparse
import sqlite3
import time
import xml.etree.ElementTree as ET
from email.utils import formatdate
from pathlib import Path

import htmlmin
import markdown
import markdown_katex


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


class Post:
    def __init__(self, html, metadata):
        self._id = None
        self.html = html
        self.metadata = metadata
        return

    @property
    def date(self):
        return self.metadata.get("date")

    @property
    def tags(self):
        return self.metadata.get("tags")

    @property
    def title(self):
        return self.metadata.get("title")

    @property
    def subtitle(self):
        return self.metadata.get("subtitle")

    @property
    def show(self):
        return self.metadata.get("show", True)

    @property
    def id(self):
        return self._id

    @id.setter
    def id(self, value):
        self._id = value


def subelement(parent, tag, text):
    e = ET.SubElement(parent, tag)
    e.text = text
    return e


def CDATA(parent, tag, text):
    child = subelement(parent, tag, None)
    return subelement(child, "![CDATA[", text)


class RssBuilder:
    def __init__(self, post_list):
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
        title = subelement(self.channel, "title", "blog.msmetko.xyz")
        link = subelement(self.channel, "link", "https://blog.msmetko.xyz")
        description = subelement(
            self.channel,
            "description",
            "Marijan Smetko writes about programming, Python, math, physics, machine and deep learning, statistics, Linux, music...",
        )
        language = subelement(self.channel, "language", "en-us")
        generator = subelement(self.channel, "generator", "msmetko")
        docs = subelement(self.channel, "docs", "https://www.rssboard.org/rss-2-0-11")
        managing_editor = subelement(
            self.channel, "managingEditor", "msmetko@msmetko.xyz"
        )
        atom_link = ET.SubElement(
            self.channel,
            "atom:link",
            {
                "href": "https://blog.msmetko.xyz/feed",
                "rel": "self",
                "type": "application/rss+xml",
            },
        )
        webmaster = subelement(self.channel, "webmaster", "msmetko@msmetko.xyz")
        subelement(self.channel, "copyright", "CC BY 4.0")
        for post in post_list:
            self.add_post(post)
        return

    def write(self, filename):
        subelement(self.channel, "pubDate", self.build_date)
        subelement(self.channel, "lastBuildDate", self.build_date)
        ET.ElementTree(self.root).write(
            filename, encoding="UTF-8", xml_declaration=True
        )
        return

    def add_post(self, post: Post):
        if post.show:
            item = ET.SubElement(self.channel, "item")
            title = CDATA(item, "title", post.title)
            description = CDATA(item, "description", post.subtitle)
            link = subelement(item, "link", LINK.format(post.id))
            author = subelement(item, "author", "msmetko@msmetko.xyz")
            for tag in post.tags:
                CDATA(item, "category", tag)
            pub_date = subelement(
                item,
                "pubDate",
                formatdate(time.mktime(post.date.timetuple())).replace("-", "+"),
            )
            dc_creator = subelement(item, "dc:creator", "Marijan Smetko")
        return


class Database:
    def __init__(self, db_con):
        self.db_con = db_con
        return

    def __enter__(self):
        return self.db_con.__enter__()

    def __exit__(self, exc_type, exc_value, traceback):
        self.db_con.__exit__(exc_type, exc_value, traceback)
        self.db_con.close()
        return

    def update_tags(self, tag_list):
        assert all(isinstance(t, str) for t in tag_list)
        cursor = self.db_con.executemany(
            "INSERT OR IGNORE INTO tags(tag_name) VALUES (?)", ((t,) for t in tag_list)
        )
        id_list = cursor.execute(
            f"SELECT id FROM tags WHERE tag_name IN ({', '.join('?' for _ in tag_list)})",
            tag_list,
        )
        return list(t[0] for t in id_list)

    def insert_post(self, post: Post):
        tag_id_list = self.update_tags(post.tags)
        post.id = self.db_con.execute(
            "INSERT INTO posts (content, title, subtitle, date, show) VALUES (?, ?, ?, ?, ?)",
            (post.html, post.title, post.subtitle, post.date, post.show),
        ).lastrowid
        self.db_con.executemany(
            "INSERT INTO post_tags (post_id, tag_id) VALUES (?, ?)",
            ((post.id, tag_id) for tag_id in tag_id_list),
        )
        return


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("files", type=Path, nargs="+")
    return parser.parse_args()


def ensure_database():
    with sqlite3.connect("db.sqlite3") as db_con:
        with open("schema.sql") as schema:
            db_con.executescript(schema.read())
            # TODO: migrations
    # here the changes are commited
    return Database(db_con)


def process_markdown(file: Path):
    content = file.read_text()
    md = markdown.Markdown(
        extensions=[
            "pymdownx.extra",
            "pymdownx.tilde",
            "markdown_katex",
            "full_yaml_metadata",
            # "mdx_urlize",
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
    html = md.convert(content)
    # TODO
    # html = htmlmin.minify(html)
    metadata = md.Meta
    post = Post(html, metadata)
    # assert post.id is not None
    return post


def main(file_list):
    db_con = ensure_database()
    post_list = sorted(
        (process_markdown(file) for file in file_list), key=lambda post: post.date
    )
    with db_con:
        for post in post_list:
            db_con.insert_post(post)
    assert all(getattr(post, "id", None) is not None for post in post_list)
    rss_builder = RssBuilder(post_list)
    rss_builder.write("feed.rss")
    return


if __name__ == "__main__":
    args = parse_args()
    main(args.files)
