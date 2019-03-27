// Copyright Keefer Taylor, 2018

import Foundation

///An abstract RPC class that defines a request and response handler.
///
/// RPCs have a generic type associated with them, which is the expected type of the decoded bytes received from the
/// network. The given RepsonseAdapter must meet this type.
///
/// RPCs represent a network request to the Tezos network. RPCs are implicitly considered GET requests by default. If a
/// payload is defined, then the RPC should be interpreted as a POST. This schema is represented in the derived
/// `isPOSTRequest` property.
///
/// Concrete subclasses should construct an endpoint and payload and inform this class by calling `super.init`.
public class RPC<T> {
  /// Re-useable headers.
  public enum Headers {
    public static func contentTypeJSON() -> [String: String ]{
      return ["Content-Type": "application/json"]
    }
  }

  public let endpoint: String
  public let headers: [[String: String]]?
  public let payload: String?
  public let responseAdapterClass: AbstractResponseAdapter<T>.Type
  public var isPOSTRequest: Bool {
    if payload != nil {
      return true
    }
    return false
  }

  /// Initialize a new request.
  ///
  /// By default, requests are considered to be GET requests with an empty body. If payload is set the request should be
  /// interpreted as a POST request with the given payload.
  ///
  /// - Parameters:
  ///   - endpoint: The endpoint to which the request is being made.
  ///   - headers: An optional dictionary of headers to use.
  ///   - responseAdapterClass: The class of the response adapter which will take bytes received from the request and
  ///     transform them into a specific type.
  ///   - payload: A payload that should be sent with a POST request.
  public init(
    endpoint: String,
    headers: [[String : String]]? = nil,
    responseAdapterClass: AbstractResponseAdapter<T>.Type,
    payload: String? = nil
  ) {
    self.endpoint = endpoint
    self.headers = headers
    self.responseAdapterClass = responseAdapterClass
    self.payload = payload
  }
}
