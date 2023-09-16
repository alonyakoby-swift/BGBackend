//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//

import Foundation
import Fluent
import Vapor

final class OrderProduct: Model, Content, Codable {
    static let schema = "order_product"

    @ID(custom: FieldKeys.id) var id: UUID?
    @Parent(key: FieldKeys.product) var product: Product
    @OptionalParent(key: FieldKeys.product) var orderTicket: OrderTicket?
    @Field(key: FieldKeys.quantity) var quantity: Int
    @Field(key: FieldKeys.comment) var comment: String
    @Field(key: FieldKeys.inspectionRequired) var inspectionRequired: Bool
    @Field(key: FieldKeys.inspectionStatus) var inspectionStatus: InspectionStatus
    
    struct FieldKeys {
        static var id: FieldKey { "id" }
        static var product: FieldKey { "product" }
        static var quantity: FieldKey { "quantity" }
        static var comment: FieldKey { "comment" }
        static var inspectionRequired: FieldKey { "inspectionRequired" }
        static var inspectionStatus: FieldKey { "inspectionStatus" }
    }

    init() { }
    
    init(id: UUID? = nil, productID: Product.IDValue, orderTicketID: OrderTicket.IDValue, quantity: Int, comment: String, inspectionRequired: Bool, inspectionStatus: InspectionStatus) {
        self.id = id
        self.$product.id = productID
        self.$orderTicket.id = orderTicketID
        self.quantity = quantity
        self.comment = comment
        self.inspectionRequired = inspectionRequired
        self.inspectionStatus = inspectionStatus
    }
}

extension OrderProductMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(OrderProduct.schema)
            .field(OrderProduct.FieldKeys.id, .uuid, .identifier(auto: true))
            .field(OrderProduct.FieldKeys.product, .uuid, .required, .references("product", "id"))
            .field(OrderProduct.FieldKeys.product, .uuid, .required, .references("order_ticket", "id"))
            .field(OrderProduct.FieldKeys.quantity, .int, .required)
            .field(OrderProduct.FieldKeys.comment, .string, .required)
            .field(OrderProduct.FieldKeys.inspectionRequired, .bool, .required)
            .field(OrderProduct.FieldKeys.inspectionStatus, .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(OrderProduct.schema).delete()
    }
}
