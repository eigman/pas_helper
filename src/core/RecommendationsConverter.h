#pragma once

#include <QString>
#include <QVariantList>

// Converts between UI recommendation blocks and @group recomendations markup.
class RecommendationsConverter {
public:
    static QString blocksToMarkup(const QVariantList& blocks);
    static QVariantList markupToBlocks(const QString& markup);

    static QString blocksToJson(const QVariantList& blocks);
    static QVariantList jsonToBlocks(const QString& json);

    // Word-like plain text: "1. item", "• item", paragraphs → blocks
    static QString blocksToPlainText(const QVariantList& blocks);
    static QVariantList plainTextToBlocks(const QString& plain);
};
